#!/usr/bin/env python3
"""
Alembic migration helper script.

This script simplifies the process of creating and applying Alembic migrations.
It provides a command-line interface to generate new migrations and upgrade the database.

Usage:
    python migrate.py "your commit message here"
    python migrate.py --upgrade
    python migrate.py --downgrade
    python migrate.py --current
"""

import argparse
import subprocess
import sys


def run_command(command):
    """Execute a shell command and return the result."""
    print(f"Running: {' '.join(command)}")
    try:
        result = subprocess.run(
            command,
            check=True,
            capture_output=True,
            text=True
        )
        if result.stdout:
            print(result.stdout)
        return True
    except subprocess.CalledProcessError as e:
        print(f"Error: {e.stderr}", file=sys.stderr)
        return False


def create_revision(message):
    """Create a new Alembic revision with the given message."""
    command = ["alembic", "revision", "--autogenerate", "-m", message]
    return run_command(command)


def upgrade_database(revision="head"):
    """Upgrade the database to the specified revision."""
    command = ["alembic", "upgrade", revision]
    return run_command(command)


def downgrade_database(revision="-1"):
    """Downgrade the database to the specified revision."""
    command = ["alembic", "downgrade", revision]
    return run_command(command)


def show_current():
    """Show the current database revision."""
    command = ["alembic", "current"]
    return run_command(command)


def show_history():
    """Show migration history."""
    command = ["alembic", "history"]
    return run_command(command)


def main():
    parser = argparse.ArgumentParser(
        description="Alembic migration helper script",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  Create a new migration:
    python migrate.py "add user table"
  
  Create and apply migration:
    python migrate.py "add user table" --auto-upgrade
  
  Upgrade database:
    python migrate.py --upgrade
  
  Downgrade one revision:
    python migrate.py --downgrade
  
  Show current revision:
    python migrate.py --current
  
  Show history:
    python migrate.py --history
        """
    )
    
    parser.add_argument(
        "message",
        nargs="?",
        help="Migration commit message (creates new revision)"
    )
    
    parser.add_argument(
        "--upgrade",
        action="store_true",
        help="Upgrade database to head"
    )
    
    parser.add_argument(
        "--downgrade",
        action="store_true",
        help="Downgrade database by one revision"
    )
    
    parser.add_argument(
        "--current",
        action="store_true",
        help="Show current database revision"
    )
    
    parser.add_argument(
        "--history",
        action="store_true",
        help="Show migration history"
    )
    
    parser.add_argument(
        "--auto-upgrade",
        action="store_true",
        help="Automatically upgrade after creating revision"
    )
    
    parser.add_argument(
        "--revision",
        type=str,
        default="head",
        help="Target revision for upgrade (default: head)"
    )
    
    args = parser.parse_args()
    
    # Check if no arguments provided
    if not any([args.message, args.upgrade, args.downgrade, args.current, args.history]):
        parser.print_help()
        sys.exit(1)
    
    success = True
    
    # Handle operations
    if args.current:
        success = show_current()
    
    elif args.history:
        success = show_history()
    
    elif args.downgrade:
        success = downgrade_database()
    
    elif args.upgrade:
        success = upgrade_database(args.revision)
    
    elif args.message:
        # Create new revision
        success = create_revision(args.message)
        
        # Optionally auto-upgrade
        if success and args.auto_upgrade:
            print("\nApplying migration...")
            success = upgrade_database()
    
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
