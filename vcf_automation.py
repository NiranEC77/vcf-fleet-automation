#!/usr/bin/env python3
"""
VCF Fleet Automation Script
Advanced automation for VMware Cloud Foundation deployments with VCF Automation and Operations
"""

import subprocess
import os
import sys
import argparse
import json
import time
from pathlib import Path
from typing import Optional, Dict, List, Any
import yaml


class VCFAutomation:
    """Advanced VCF automation class with fleet management capabilities"""
    
    def __init__(self, config_dir: str, environment: str = "dev"):
        self.config_dir = Path(config_dir)
        self.environment = environment
        self.work_dir = self.config_dir / environment
        self.state_file = self.work_dir / "vcf-state.json"
        
        if not self.work_dir.exists():
            raise FileNotFoundError(f"Config directory not found: {self.work_dir}")
    
    def run_command(self, cmd: List[str], check: bool = True, capture_output: bool = True) -> subprocess.CompletedProcess:
        """Run a command with enhanced error handling"""
        print(f"🔧 Running: {' '.join(cmd)}")
        
        result = subprocess.run(
            cmd,
            cwd=self.work_dir,
            capture_output=capture_output,
            text=True,
            check=check
        )
        
        if result.stdout and capture_output:
            print(f"📤 Output: {result.stdout}")
        if result.stderr and capture_output:
            print(f"⚠️  Error: {result.stderr}")
            
        return result
    
    def save_state(self, state: Dict[str, Any]) -> None:
        """Save automation state to file"""
        with open(self.state_file, 'w') as f:
            json.dump(state, f, indent=2)
    
    def load_state(self) -> Dict[str, Any]:
        """Load automation state from file"""
        if self.state_file.exists():
            with open(self.state_file, 'r') as f:
                return json.load(f)
        return {}
    
    def init_terraform(self) -> bool:
        """Initialize Terraform with VCF provider"""
        print(f"📦 Initializing Terraform for VCF in {self.work_dir}")
        try:
            result = self.run_command(["terraform", "init"])
            print("✅ Terraform initialized successfully")
            return True
        except subprocess.CalledProcessError as e:
            print(f"❌ Error initializing Terraform: {e.stderr}")
            return False
    
    def validate_config(self) -> bool:
        """Validate VCF configuration"""
        print(f"✅ Validating VCF configuration in {self.work_dir}")
        try:
            result = self.run_command(["terraform", "validate"])
            print("✅ Configuration validation passed")
            return True
        except subprocess.CalledProcessError as e:
            print(f"❌ Configuration validation failed: {e.stderr}")
            return False
    
    def plan_deployment(self, output_file: Optional[str] = None) -> Optional[str]:
        """Create VCF deployment plan"""
        print(f"📋 Creating VCF deployment plan for {self.environment}")
        cmd = ["terraform", "plan", "-detailed-exitcode"]
        
        if output_file:
            cmd.extend(["-out", output_file])
        
        try:
            result = self.run_command(cmd)
            
            if result.returncode == 0:
                print("✅ No changes needed - infrastructure is up to date")
                return None
            elif result.returncode == 2:
                print("📝 Changes detected - plan created")
                if output_file:
                    return str(self.work_dir / output_file)
                return "plan_created"
            else:
                print(f"❌ Error creating plan: {result.stderr}")
                return None
        except subprocess.CalledProcessError as e:
            print(f"❌ Error planning: {e.stderr}")
            return None
    
    def deploy_vcf_fleet(self, plan_file: Optional[str] = None, auto_approve: bool = False) -> bool:
        """Deploy VCF fleet with VCF Automation and Operations"""
        print(f"🚀 Deploying VCF fleet to {self.environment}")
        
        # Save deployment state
        state = self.load_state()
        state.update({
            "deployment_started": time.time(),
            "environment": self.environment,
            "status": "deploying"
        })
        self.save_state(state)
        
        cmd = ["terraform", "apply"]
        
        if auto_approve:
            cmd.append("-auto-approve")
        elif plan_file:
            cmd.append(plan_file)
        
        try:
            result = self.run_command(cmd)
            print("✅ VCF fleet deployment completed!")
            
            # Update state
            state.update({
                "deployment_completed": time.time(),
                "status": "deployed"
            })
            self.save_state(state)
            
            return True
        except subprocess.CalledProcessError as e:
            print(f"❌ Error deploying VCF fleet: {e.stderr}")
            state.update({"status": "failed"})
            self.save_state(state)
            return False
    
    def destroy_vcf_fleet(self, auto_approve: bool = False) -> bool:
        """Destroy VCF fleet (use with extreme caution!)"""
        print(f"⚠️  DESTROYING VCF fleet in {self.environment}")
        
        if not auto_approve:
            confirm = input("Type 'DESTROY' to confirm VCF fleet destruction: ")
            if confirm != "DESTROY":
                print("❌ Destruction cancelled")
                return False
        
        cmd = ["terraform", "destroy"]
        if auto_approve:
            cmd.append("-auto-approve")
        
        try:
            result = self.run_command(cmd)
            print("✅ VCF fleet destruction completed!")
            
            # Clear state
            if self.state_file.exists():
                self.state_file.unlink()
            
            return True
        except subprocess.CalledProcessError as e:
            print(f"❌ Error destroying VCF fleet: {e.stderr}")
            return False
    
    def get_vcf_status(self) -> Dict[str, Any]:
        """Get comprehensive VCF fleet status"""
        print(f"📊 Getting VCF fleet status for {self.environment}")
        
        status = {
            "environment": self.environment,
            "timestamp": time.time(),
            "terraform_state": {},
            "outputs": {},
            "resources": [],
            "pending_changes": False
        }
        
        try:
            # Get Terraform state
            result = self.run_command(["terraform", "show", "-json"])
            if result.returncode == 0:
                status["terraform_state"] = json.loads(result.stdout)
            
            # Get resource list
            result = self.run_command(["terraform", "state", "list"])
            if result.returncode == 0:
                status["resources"] = result.stdout.strip().split('\n')
            
            # Get outputs
            result = self.run_command(["terraform", "output", "-json"])
            if result.returncode == 0:
                status["outputs"] = json.loads(result.stdout)
            
            # Check for pending changes
            result = self.run_command(["terraform", "plan", "-detailed-exitcode"])
            if result.returncode == 2:
                status["pending_changes"] = True
            
            # Load automation state
            status["automation_state"] = self.load_state()
            
        except subprocess.CalledProcessError as e:
            print(f"⚠️  Error getting status: {e.stderr}")
            status["error"] = str(e)
        
        return status
    
    def show_vcf_outputs(self) -> None:
        """Show VCF deployment outputs"""
        print(f"📤 VCF Fleet Outputs for {self.environment}:")
        try:
            result = self.run_command(["terraform", "output"])
            print(result.stdout)
        except subprocess.CalledProcessError as e:
            print(f"❌ Error getting outputs: {e.stderr}")
    
    def export_vcf_config(self, output_file: str) -> bool:
        """Export VCF configuration to YAML"""
        print(f"📄 Exporting VCF configuration to {output_file}")
        
        try:
            # Get current configuration
            status = self.get_vcf_status()
            
            # Create export data
            export_data = {
                "environment": self.environment,
                "timestamp": time.time(),
                "terraform_state": status.get("terraform_state", {}),
                "outputs": status.get("outputs", {}),
                "resources": status.get("resources", []),
                "automation_state": status.get("automation_state", {})
            }
            
            # Write to file
            with open(output_file, 'w') as f:
                yaml.dump(export_data, f, default_flow_style=False, indent=2)
            
            print(f"✅ Configuration exported to {output_file}")
            return True
            
        except Exception as e:
            print(f"❌ Error exporting configuration: {e}")
            return False
    
    def validate_vcf_connectivity(self) -> bool:
        """Validate connectivity to VCF components"""
        print("🔍 Validating VCF connectivity...")
        
        try:
            # Check if we can get outputs (indicates successful connection)
            result = self.run_command(["terraform", "output", "-json"])
            if result.returncode == 0:
                outputs = json.loads(result.stdout)
                
                # Check for key VCF components
                required_outputs = [
                    "vcenter_fleet_url",
                    "vcenter_workload_url", 
                    "nsx_fleet_url",
                    "nsx_workload_url"
                ]
                
                missing = [output for output in required_outputs if output not in outputs]
                if missing:
                    print(f"⚠️  Missing expected outputs: {missing}")
                    return False
                
                print("✅ VCF connectivity validated")
                return True
            else:
                print("❌ Cannot connect to VCF - check configuration")
                return False
                
        except Exception as e:
            print(f"❌ Error validating connectivity: {e}")
            return False


def main():
    parser = argparse.ArgumentParser(description="VCF Fleet Automation Script")
    parser.add_argument(
        "command",
        choices=["init", "validate", "plan", "deploy", "destroy", "status", "outputs", "export", "validate-connectivity"],
        help="VCF automation command to execute"
    )
    parser.add_argument(
        "--config-dir",
        default="./configs",
        help="Directory containing environment configs (default: ./configs)"
    )
    parser.add_argument(
        "--environment",
        default="dev",
        help="Environment to deploy to (default: dev)"
    )
    parser.add_argument(
        "--auto-approve",
        action="store_true",
        help="Auto-approve changes (use with caution)"
    )
    parser.add_argument(
        "--output-file",
        help="Output file for plan or export commands"
    )
    
    args = parser.parse_args()
    
    try:
        vcf = VCFAutomation(args.config_dir, args.environment)
        
        if args.command == "init":
            success = vcf.init_terraform()
        elif args.command == "validate":
            success = vcf.validate_config()
        elif args.command == "plan":
            plan_file = vcf.plan_deployment(args.output_file)
            success = plan_file is not None
        elif args.command == "deploy":
            success = vcf.deploy_vcf_fleet(args.output_file, args.auto_approve)
        elif args.command == "destroy":
            success = vcf.destroy_vcf_fleet(args.auto_approve)
        elif args.command == "status":
            status = vcf.get_vcf_status()
            print(json.dumps(status, indent=2))
            success = True
        elif args.command == "outputs":
            vcf.show_vcf_outputs()
            success = True
        elif args.command == "export":
            output_file = args.output_file or f"vcf-{args.environment}-config.yaml"
            success = vcf.export_vcf_config(output_file)
        elif args.command == "validate-connectivity":
            success = vcf.validate_vcf_connectivity()
        
        sys.exit(0 if success else 1)
    
    except FileNotFoundError as e:
        print(f"❌ Error: {e}")
        sys.exit(1)
    except KeyboardInterrupt:
        print("\n❌ Operation cancelled by user")
        sys.exit(1)


if __name__ == "__main__":
    main()
