# Cloudflare Load Balancer — Terraform

Create and manage Cloudflare Load Balancers using `.tfvars` files — **one
folder per load balancer**. Open a pull request, review the plan, merge —
GitHub Actions applies it. No local Terraform commands required.

```
.
├── .github/workflows/terraform.yml   # CI/CD: plan on PR, apply on merge
├── modules/
│   └── load-balancer/                # The engine (monitor + pools + load balancer) — NEVER TOUCHED
└── load-balancer/
    ├── engine/                       # All the Terraform code — DO NOT TOUCH
    │   ├── provider.tf
    │   ├── backend.tf                #   set ONCE (your R2 bucket + account id)
    │   ├── variables.tf
    │   └── main.tf
    └── load-balancer-configs/        # ← COPY THIS FOLDER for each load balancer
        ├── settings.tfvars           #   name, hostname, account/zone, proxied, steering, affinity, fallback
        ├── pools.tfvars              #   pools + origin endpoints (private IPs supported)
        └── monitor.tfvars            #   health check
```

## The idea

- **`modules/load-balancer`** — the reusable module. Never touched.
- **`load-balancer/engine/`** — all the Terraform plumbing lives here, away from
  where you make edits. You only set `backend.tf` once; never touch the rest.
- **`load-balancer/load-balancer-configs/`** — the three `.tfvars` files that
  describe one load balancer. **Copy this folder** to create each load balancer:

  ```bash
  cd load-balancer
  cp -r load-balancer-configs web-lb   # "web-lb" becomes the load balancer's id
  ```

Every load balancer gets its **own state file** (`load-balancers/<name>.tfstate`
in your R2 bucket).

---

## Create a load balancer (the only thing you do)

```bash
cd load-balancer
cp -r load-balancer-configs acme     # the new folder name "acme" becomes the LB id
# edit acme/settings.tfvars    -> account_id, zone_id, hostname, steering, affinity
# edit acme/pools.tfvars       -> your origin endpoints (+ virtual_network_id for private IPs)
# edit acme/monitor.tfvars     -> health check (optional)
```

Add more load balancers by copying `load-balancer-configs` to another folder
(`globex`, `initech`, …). Every folder under `load-balancer/` is deployed,
**except** `engine` and the `load-balancer-configs` template.

Then commit on a branch, open a pull request (the plan is posted as a comment),
and merge to `main` to apply.

> **Private IPs:** set `virtual_network_id` on each origin in `pools.tfvars` to
> the Cloudflare virtual network (Magic WAN / Tunnel) that can reach them. For
> public IPs/hostnames, remove that line.

Every field and its allowed values is documented inline in the
`load-balancer-configs` tfvars and in `modules/load-balancer/variables.tf`.

---

## One-time setup

### 1. Cloudflare API token (manages the load balancers)
Dashboard → **My Profile → API Tokens → Create Token → Create Custom Token**.

Grant the following permissions:

**Account** (Account Resources → your account):
- **Load Balancing: Account Load Balancers** · Edit
- **Notifications** · Edit
- **Load Balancing: Monitors and Pools** · Edit

**Zone** (Zone Resources → All zones, or the specific zones you serve):
- **DNS Settings** · Edit
- **Load Balancers** · Edit
- **DNS** · Edit

Create the token and copy its value (shown once) — you'll store it as the
`CLOUDFLARE_API_TOKEN` GitHub secret in Step 3.

### 2. Create an R2 bucket for Terraform state
Terraform needs to remember what it created. We store that "state" in **your**
Cloudflare R2 bucket.

1. Dashboard → **R2** → **Create bucket**, e.g. `my-tf-state`.
2. R2 → **Manage R2 API Tokens** → **Create API token** → permission
   **Object Read & Write** → copy the **Access Key ID** and **Secret Access
   Key** it shows you.
3. Edit **`load-balancer/engine/backend.tf`** and set:
   - `bucket` → your bucket name (e.g. `my-tf-state`)
   - the account id in the `endpoints.s3` URL → your Cloudflare **Account ID**
     (so it becomes `https://<ACCOUNT_ID>.r2.cloudflarestorage.com`)

> Where do I find my Account ID? Dashboard → any domain → Overview (right
> sidebar), or R2 → the S3 API endpoint shown for your bucket.

### 3. GitHub repository secrets
Repo → **Settings → Secrets and variables → Actions → New repository secret**:

| Secret name            | Value                                |
|------------------------|--------------------------------------|
| `CLOUDFLARE_API_TOKEN` | the API token from step 1            |
| `R2_ACCESS_KEY_ID`     | the R2 Access Key ID from step 2     |
| `R2_SECRET_ACCESS_KEY` | the R2 Secret Access Key from step 2 |

That's it. From now on, copying a config folder + merging is all it takes.

---

## How the automation works

`.github/workflows/terraform.yml`:
- Discovers every folder under `load-balancer/` (skipping `engine` and the
  `load-balancer-configs` template) and runs one Terraform job per load
  balancer, each with its own state file.
- On a **pull request**: runs `terraform plan` and posts it as a PR comment.
- On **merge to `main`**: runs `terraform apply` on the reviewed plan.

So adding a new load balancer folder "just works" — no workflow changes needed.
