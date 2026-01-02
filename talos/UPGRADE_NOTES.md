# Talos Cluster Upgrade Notes

## Talos v1.12.0 with Longhorn iscsi-tools

### Current Status (2026-01-02)
- **Updated nodes**: preprod-worker-01, preprod-bootstrap-controlplane (manually upgraded to v1.12.0)
- **Pending nodes**: preprod-controlplane-01, preprod-controlplane-02, preprod-worker-02, preprod-worker-03 (still on v1.11.2)

### Why This Upgrade?
The cluster requires **iscsi-tools** system extension for Longhorn distributed storage to function properly.

**Without iscsi-tools**, Longhorn manager pods fail with:
```
Error: failed to execute iscsiadm: No such file or directory
```

### Schematic Information
- **Schematic ID**: `53513e54bb39202f35694412577a6bc53d484744d35a126e5d42ef34785c0d83`
- **Includes**:
  - `qemu-guest-agent` (v10.1.3) - VM guest integration
  - `iscsi-tools` (v0.2.0) - iSCSI initiator for Longhorn volumes
  - `util-linux-tools` (v2.41.2) - System utilities (nsenter, mount, etc.)

### Applying the Upgrade

The `main.tf` has been updated with:
1. Talos version bumped from v1.11.2 → v1.12.0
2. Proper extensions configuration
3. Detailed comments explaining each component

To apply to remaining nodes:

```bash
# Review the changes
tofu plan

# Apply the upgrade (nodes will reboot one at a time)
tofu apply

# Verify all nodes have iscsi-tools
export TALOSCONFIG=preprod.talosconfig
talosctl --nodes 10.198.141.71,10.198.141.72,10.198.141.74,10.198.141.75 get extensions
```

### Post-Upgrade Verification

Check that all Longhorn managers are healthy:
```bash
kubectl get pods -n longhorn-system -l app=longhorn-manager
```

All pods should show `2/2 Running` status.

### Important Notes

⚠️ **Node Reboots**: Each node will reboot during the upgrade. The upgrade is rolling, so the cluster will remain operational.

⚠️ **Pod Rescheduling**: Pods on upgrading nodes will be rescheduled to other nodes automatically.

⚠️ **Schematic Persistence**: Once applied via Terraform, the schematic is permanent and will survive reboots.

### Rollback (if needed)

If issues occur, you can rollback by:
1. Reverting `talos_version` to `"1.11.2"` in `main.tf`
2. Running `tofu apply`

**Note**: Longhorn will not work on v1.11.2 without iscsi-tools!
