# Talos

Talos-specific assets for this homelab cluster. The current contents are focused on generating a custom Talos Image Factory installer image with the system extensions required by the Kubernetes platform.

## Layout

```text
talos/
├── README.md
└── image/
    ├── generate.sh      # Posts the schematic to Talos Image Factory
    ├── schematic.yaml   # Image customization definition
    └── version.env      # Default Talos version used by generate.sh
```

## Custom Image

The image schematic enables the official `siderolabs/iscsi-tools` system extension. This is useful for storage components such as Longhorn that depend on iSCSI tooling on Talos nodes.

`siderolabs/qemu-guest-agent` is present in the schematic as a commented option and can be enabled if the cluster nodes run as QEMU guests and need guest-agent integration.

## Prerequisites

- `bash`
- `curl`
- `python3`
- `talosctl`, for applying upgrades after generating the image
- Network access to `https://factory.talos.dev`

## Generate the Installer Image

Run the helper script from the repository root:

```sh
./talos/image/generate.sh
```

The script:

1. Reads `talos/image/schematic.yaml`.
2. Posts it to Talos Image Factory.
3. Parses the returned schematic ID.
4. Prints the matching `factory.talos.dev/metal-installer/...` image.

The Talos version defaults to `TALOS_VERSION` in `talos/image/version.env`:

```sh
TALOS_VERSION=v1.13.5
```

You can override the version for a single run:

```sh
TALOS_VERSION=v1.13.6 ./talos/image/generate.sh
```

You can also point the script at a different Image Factory endpoint:

```sh
IMAGE_FACTORY=https://factory.talos.dev ./talos/image/generate.sh
```

## Upgrade a Node

After generating an installer image, use the printed image with `talosctl upgrade`:

```sh
talosctl upgrade \
  --nodes 192.168.1.231 \
  --image factory.talos.dev/metal-installer/<schematic-id>:<talos-version>
```

Replace the node address, schematic ID, and Talos version with the values for the target node and generated image.

For multi-node clusters, upgrade one node at a time and verify cluster health between nodes:

```sh
talosctl health
kubectl get nodes
kubectl get pods --all-namespaces
```

## Maintenance

- Update `talos/image/version.env` when adopting a new Talos release.
- Update `talos/image/schematic.yaml` when adding or removing Talos system extensions.
- Re-run `./talos/image/generate.sh` after any schematic or version change.
- Keep generated schematic IDs in operational notes or change records if you need to track exactly which image was installed on each node.
