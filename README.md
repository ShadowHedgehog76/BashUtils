# 🐚 BashUtils

A comprehensive collection of Bash utilities for system administration, development, and daily tasks. Make your command-line life easier! ✨

## 🚀 Quick Start

### Installation

Install all BashUtils with a single command:

```bash
curl -fsSL https://raw.githubusercontent.com/ShadowHedgehog76/BashUtils/main/install.sh | bash
```

Or clone and install manually:

```bash
git clone https://github.com/ShadowHedgehog76/BashUtils.git
cd BashUtils
chmod +x *.sh
```

### Interactive Menu

Access all utilities through the unified menu system:

```bash
./menu.sh
```

Or run commands directly:

```bash
./menu.sh --direct "sysinfo --help"
```

## 📋 Complete Utility Suite

### 🔍 **System Information & Monitoring**

| Script | Description | Key Features |
|--------|-------------|--------------|
| `sysinfo.sh` | Comprehensive system information | CPU, memory, disk, network details with JSON output |
| `monitor.sh` | Real-time system monitoring | CPU/memory/disk alerts, continuous monitoring |
| `envcheck.sh` | Environment and tool checker | Validate installed tools, development environment |

### 🌐 **Network & Security Tools**

| Script | Description | Key Features |
|--------|-------------|--------------|
| `network.sh` | Network device discovery | ARP scanning, device detection, network mapping |
| `ports.sh` | Port scanner and service detector | TCP/UDP scanning, service identification |
| `dns.sh` | DNS lookup and testing | Query resolution, connectivity testing |
| `speedtest.sh` | Network speed testing | Download speed, latency measurement |
| `webcheck.sh` | Website availability checker | HTTP status, SSL validation, response times |
| `secure.sh` | Security checker and hardening | Basic security audit, recommendations |

### 🛠️ **File & System Management**

| Script | Description | Key Features |
|--------|-------------|--------------|
| `search.sh` | Advanced text and file search | Regex patterns, recursive search, filtering |
| `cleanup.sh` | System cleanup utility | Temp files, logs, cache cleaning with dry-run |
| `backup.sh` | File and directory backup | Compressed archives, selective backup |
| `organize.sh` | File organization tool | Sort by type, date, or size |
| `logs.sh` | Log analyzer and viewer | System log analysis, filtering, following |

### 💻 **Development Tools**

| Script | Description | Key Features |
|--------|-------------|--------------|
| `gitutils.sh` | Git repository management | Status, cleanup, sync, backup operations |
| `deploy.sh` | Deployment automation | rsync, scp, git deployment methods |

### ⚙️ **Installation & Management**

| Script | Description | Key Features |
|--------|-------------|--------------|
| `install.sh` | GitHub-based installation | Download all scripts, dependency checking |
| `update.sh` | Automatic update system | Hash-based updates, backup creation |
| `setup-alias.sh` | Alias configuration | Convenient command shortcuts |
| `menu.sh` | Interactive unified menu | Access all tools, auto-refresh interface |

## 🌍 Multi-Language Support

All scripts support multiple languages:
- `--en` English (default)
- `--fr` French  
- `--jp` Japanese

```bash
./sysinfo.sh --fr    # Display help in French
./network.sh --jp    # Display help in Japanese
```

## 💡 Usage Examples

### Quick System Check
```bash
./sysinfo.sh              # Basic system info
./monitor.sh --continuous # Real-time monitoring
./secure.sh --type basic  # Security audit
```

### Network Diagnostics
```bash
./network.sh --scan       # Discover network devices
./ports.sh --range 1-1000 # Scan common ports
./dns.sh google.com       # Test DNS resolution
./speedtest.sh            # Check internet speed
```

### File Operations
```bash
./search.sh "TODO" . --name "*.js"        # Find TODOs in JS files
./cleanup.sh --dry-run                    # Preview cleanup
./backup.sh ~/important-docs              # Create backup
./organize.sh ~/Downloads --mode type     # Sort files by type
```

### Development Workflow
```bash
./envcheck.sh --type dev                  # Check dev environment
./gitutils.sh status                      # Enhanced git status
./deploy.sh --method rsync user@server:/  # Deploy application
```

## 🔧 Advanced Features

### JSON Output
Many utilities support JSON output for scripting:
```bash
./sysinfo.sh --json
./envcheck.sh --format json
./webcheck.sh --format json https://example.com
```

### Dry Run Mode
Test operations safely:
```bash
./cleanup.sh --dry-run    # Preview cleanup actions
./deploy.sh --dry-run     # Preview deployment
```

### Filtering and Options
Powerful filtering and customization:
```bash
./search.sh --regex "^class\s+\w+" . --exclude "node_modules"
./monitor.sh --cpu-threshold 90 --alert-mode both
./ports.sh --target 192.168.1.1 --format json
```

## 📁 Installation Locations

Scripts can be installed in various locations:
- Current directory (manual installation)
- `~/bin/` (recommended for personal use)
- `/usr/local/bin/` (system-wide installation)

## 🤝 Contributing

Feel free to contribute improvements, bug fixes, or new utilities:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Happy scripting!** 🚀