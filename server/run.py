#!/usr/bin/env python3
"""
Simple Docker Compose runner for Kronyx
Usage: 
    python run.py         # Start containers
    python run.py stop    # Stop containers
"""

import subprocess
import sys
from pathlib import Path


def run_docker_compose(command: list[str]):
    """Execute docker-compose command."""
    try:
        result = subprocess.run(
            command,
            cwd=Path(__file__).parent,
            check=True
        )
        return result.returncode
    except subprocess.CalledProcessError as e:
        print(f"Error: {e}")
        sys.exit(1)


def start():
    """Start Docker containers."""
    print("Building and starting containers...")
    run_docker_compose(["docker-compose", "up", "-d", "--build"])
    print("\n✓ Containers started successfully!")
    print("\nView logs: docker-compose logs -f")
    print("Stop containers: python run.py stop")


def stop():
    """Stop Docker containers."""
    print("Stopping containers...")
    run_docker_compose(["docker-compose", "down"])
    print("\n✓ Containers stopped successfully!")


def main():
    if len(sys.argv) > 1 and sys.argv[1] == "stop":
        stop()
    else:
        start()


if __name__ == "__main__":
    main()
