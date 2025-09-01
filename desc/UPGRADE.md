# PostgreSQL Upgrade Guide: Version 13 to 15

This document provides a comprehensive guide for upgrading PostgreSQL from version 13.x to 15.x (e.g., from 13.20 to 15.13) using the `lsys_postgresql` Puppet module.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Pre-Upgrade Checklist](#pre-upgrade-checklist)
4. [Upgrade Methods](#upgrade-methods)
5. [Step-by-Step Upgrade Process](#step-by-step-upgrade-process)
6. [Post-Upgrade Tasks](#post-upgrade-tasks)
7. [Rollback Procedure](#rollback-procedure)
8. [Troubleshooting](#troubleshooting)
9. [Performance Considerations](#performance-considerations)

## Overview

PostgreSQL 15 introduces several new features and improvements over version 13:

- Enhanced performance for sorting and window functions
- Improved logical replication capabilities
- Better query planning and execution
- Security enhancements including stronger password encryption
- New built-in functions and SQL features

**Important:** This upgrade spans two major versions (13 → 14 → 15). While `pg_upgrade` can handle this directly, ensure thorough testing.

## Prerequisites

### System Requirements

- **Disk Space**: Ensure at least 2x the current database size for the upgrade process
- **Memory**: Minimum 4GB RAM recommended for medium-sized databases
- **Backup Storage**: Sufficient space for full database backup
- **Downtime Window**: Plan for 30 minutes to several hours depending on database size

### Software Requirements

- PostgreSQL 15 packages installed alongside PostgreSQL 13
- `pg_upgrade` utility (included with PostgreSQL 15)
- Access to both old and new PostgreSQL binaries
- Root or postgresql user privileges

## Pre-Upgrade Checklist

### 1. Environment Assessment

```bash
# Check current PostgreSQL version
psql -c "SELECT version();"
                                                    version
---------------------------------------------------------------------------------------------------------------
 PostgreSQL 13.20 on x86_64-redhat-linux-gnu, compiled by gcc (GCC) 11.5.0 20240719 (Red Hat 11.5.0-5), 64-bit
(1 row)
```

```
# Check database sizes
psql -c "SELECT datname, pg_size_pretty(pg_database_size(datname)) FROM pg_database;"
       datname       | pg_size_pretty
---------------------+----------------
 postgres            | 7949 kB
 template1           | 7777 kB
 template0           | 7777 kB
 gitlabhq_production | 419 MB
(4 rows)
```

```
# Check for deprecated features
psql -c "SELECT * FROM pg_settings WHERE name LIKE '%deprecated%';"
```

### 2. Backup Strategy

```bash
# Full cluster backup using pg_dumpall
pg_dumpall -U postgres > /backup/full_backup_$(date +%Y%m%d_%H%M%S).sql

# Individual database backups
for db in $(psql -t -c "SELECT datname FROM pg_database WHERE datname NOT IN ('template0', 'template1', 'postgres');"); do
    pg_dump -U postgres -Fc $db > /backup/${db}_$(date +%Y%m%d_%H%M%S).backup
done
```

### 3. Configuration Backup

```bash
# Backup configuration files
cp -a /var/lib/pgsql/data /backup/
cp /var/lib/pgsql/data/*.conf /backup/
```

### 4. Extension Compatibility Check

```sql
-- Check installed extensions
SELECT extname, extversion FROM pg_extension;

-- Check for extensions that may need updates
\dx
```

## Upgrade Methods

### Method 1: In-Place Upgrade (Recommended)

Uses `pg_upgrade` utility for faster migration with minimal downtime.

### Method 2: Dump and Restore

Traditional method using `pg_dump` and `pg_restore` - slower but more reliable for complex scenarios.

## Step-by-Step Upgrade Process

### Phase 1: Installation and Preparation

#### 1. Install PostgreSQL 15

```bash
# For RHEL/CentOS/Rocky Linux
yum install -y postgresql15-server postgresql15

# For Ubuntu/Debian
apt-get install postgresql-15 postgresql-client-15
```

#### 2. Stop PostgreSQL 13 Service

```bash
systemctl stop postgresql-13
# or
/usr/pgsql-13/bin/pg_ctl -D /var/lib/pgsql/data stop
```

#### 3. Initialize PostgreSQL 15 Data Directory

```bash
/usr/pgsql-15/bin/initdb -D /var/lib/pgsql/15/data
```

### Phase 2: Upgrade Execution

#### 1. Run Compatibility Check

```bash
/usr/pgsql-15/bin/pg_upgrade \
    --old-bindir=/usr/bin \
    --new-bindir=/usr/pgsql-15/bin \
    --old-datadir=/var/lib/pgsql/data \
    --new-datadir=/var/lib/pgsql/15/data \
    --check
```

#### 2. Execute the Upgrade

```bash
/usr/pgsql-15/bin/pg_upgrade \
    --old-bindir=/usr/bin \
    --new-bindir=/usr/pgsql-15/bin \
    --old-datadir=/var/lib/pgsql/data \
    --new-datadir=/var/lib/pgsql/15/data \
    --verbose \
    --retain
```

### Phase 3: Service Configuration

#### 1. Update Service Configuration

```bash
# Update systemd service
systemctl disable postgresql-13
systemctl enable postgresql-15

# Update default data directory
sed -i 's|/var/lib/pgsql/data|/var/lib/pgsql/15/data|g' /etc/systemd/system/postgresql.service
systemctl daemon-reload
```

#### 2. Start PostgreSQL 15

```bash
systemctl start postgresql-15

# or
/usr/pgsql-15/bin/pg_ctl -D /var/lib/pgsql/15/data start
```

## Post-Upgrade Tasks

### 1. Verify Upgrade Success

```bash
# Check version
psql -c "SELECT version();"

# Verify databases
psql -l

# Check for any missing objects
psql -c "SELECT * FROM information_schema.tables WHERE table_schema = 'public';"
```

### 2. Update Statistics

```bash
# Run analyze on all databases
psql -c "VACUUM ANALYZE;"

# Update planner statistics
/usr/pgsql-15/bin/vacuumdb --all --analyze-in-stages
```

### 3. Update Extensions

```sql
-- Update extensions to latest versions
\dx
ALTER EXTENSION extension_name UPDATE;
```

using command:

```
/usr/pgsql-15/bin/psql -U postgres -d gitlabhq_production -f update_extensions.sql
```

### 4. Configuration Migration

```bash
# Compare and merge configuration changes
diff backups/postgresql.conf /var/lib/pgsql/15/data/postgresql.conf
diff backups/pg_hba.conf /var/lib/pgsql/15/data/pg_hba.conf
```

### 5. Performance Tuning

```sql
-- Update configuration for PostgreSQL 15 optimizations
ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements';
ALTER SYSTEM SET track_activities = on;
ALTER SYSTEM SET track_counts = on;
SELECT pg_reload_conf();
```

## Rollback Procedure

### If Upgrade Fails Before Completion

1. **Stop PostgreSQL 15**:
   ```bash
   systemctl stop postgresql-15
   ```

2. **Restore PostgreSQL 13**:
   ```bash
   systemctl start postgresql-13
   ```

3. **Verify Data Integrity**:
   ```bash
   psql -c "SELECT datname FROM pg_database;"
   ```

### If Upgrade Completes But Issues Arise

1. **Stop PostgreSQL 15**:
   ```bash
   systemctl stop postgresql-15
   ```

2. **Restore from Backup**:
   ```bash
   # Restore full cluster
   dropdb --if-exists database_name
   psql -f /backup/full_backup_YYYYMMDD_HHMMSS.sql
   ```

3. **Restart PostgreSQL 13**:
   ```bash
   systemctl start postgresql-13
   ```

## Troubleshooting

### Common Issues and Solutions

#### Issue: pg_upgrade fails with "mismatch of relation OID"

**Solution:**
```bash
# Ensure both clusters are stopped
systemctl stop postgresql-13 postgresql-15

# Re-run with --check flag first
/usr/pgsql-15/bin/pg_upgrade --check [options]
```

#### Issue: Extensions not found

**Solution:**
```bash
# Install missing extensions for PostgreSQL 15
yum install postgresql15-contrib

# Manually update extensions after upgrade
psql -c "ALTER EXTENSION extension_name UPDATE;"
```

#### Issue: Permission denied errors

**Solution:**
```bash
# Ensure correct ownership
chown -R postgres:postgres /var/lib/pgsql/15/
chmod 700 /var/lib/pgsql/15/data
```

#### Issue: Memory errors during upgrade

**Solution:**
```bash
# Increase memory settings temporarily
echo 'vm.overcommit_memory = 2' >> /etc/sysctl.conf
sysctl -p
```

### Log Analysis

```bash
# Check PostgreSQL logs
tail -f /var/lib/pgsql/15/data/log/postgresql-*.log

# Check system logs
journalctl -u postgresql-15 -f
```

## Performance Considerations

### New Features in PostgreSQL 15

1. **Improved Sorting Performance**: Especially beneficial for large datasets
2. **Enhanced Parallel Query Processing**: Better utilization of multiple CPU cores
3. **Optimized Window Functions**: Faster analytical queries
4. **Better Memory Management**: Reduced memory fragmentation

### Post-Upgrade Optimization

```sql
-- Enable new features
SET enable_parallel_hash = on;
SET work_mem = '256MB';  -- Adjust based on available RAM

-- Update table statistics
ANALYZE;

-- Consider partitioning for large tables (new native partitioning features)
```

### Monitoring

```sql
-- Enable query statistics collection
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Monitor upgrade impact
SELECT query, calls, total_time, mean_time
FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 10;
```

---

**Note**: This guide is based on the upgrade history found in the original UPGRADE.md file and follows PostgreSQL best practices. Always test the upgrade process in a development environment before applying to production systems.

**Last Updated**: September 2025
**PostgreSQL Versions Covered**: 13.x → 15.x
