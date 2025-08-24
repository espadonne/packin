# Sultree YUM Repository

This repository contains RPM packages for `sultree` - a SELinux-aware tree command.

## Installation Instructions

### Method 1: Add Repository (Recommended)

1. Download the repository configuration:
```bash
sudo wget -O /etc/yum.repos.d/sultree.repo https://repos.musicsian.com/sultree/sultree.repo
```

2. Update your baseurl in `/etc/yum.repos.d/sultree.repo` to point to your actual domain.

3. Install sultree:
```bash
sudo dnf install sultree
```

### Method 2: Direct RPM Installation

Download and install the RPM directly:
```bash
sudo dnf install https://repos.musicsian.com/sultree/RPMS/sultree-0.0.8-1.el9.noarch.rpm
```

## Usage

After installation, use `sultree` just like the regular `tree` command, with additional SELinux filtering:

```bash
# Basic usage
sultree

# Filter by SELinux context
sultree -S passwd_file_t /etc

# Combine with other tree options  
sultree -S "*admin*" -L 2 /var/log
```

## Repository Hosting

To host this repository, upload the entire `sultree-repo` directory to your web server and ensure:

1. The directory is accessible via HTTP/HTTPS
2. Update the `baseurl` in `sultree.repo` to your actual domain
3. Set proper permissions (readable by web server)

## Package Information

- **Package**: sultree-0.0.8-1.el9.noarch.rpm
- **License**: MIT
- **Dependencies**: python3 >= 3.8, attr
- **Architecture**: noarch (works on all architectures)
- **Compatible with**: RHEL 9, CentOS Stream 9, Rocky Linux 9, AlmaLinux 9, Fedora

## Support

For issues and bug reports, visit: https://github.com/username/sultree/issues