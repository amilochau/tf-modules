<p align="center">
  <a href="https://github.com/amilochau/tf-modules/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/amilochau/tf-modules" alt="License">
  </a>
  <a href="https://github.com/amilochau/tf-modules/releases">
    <img src="https://img.shields.io/github/v/release/amilochau/tf-modules" alt="Release">
  </a>
</p>
<h1 align="center">
  amilochau/tf-modules
</h1>

`tf-modules` is a set of Terraform modules developed to help creating infrastructure for `amilochau` projects.

---

## Terraform modules

The following modules are proposed for Infrastructure as Code, and can be freely used:

| Path | Description |
| ---- | ----------- |
| [aws/auth](./aws/auth) | Deploys AWS Cognito resources for identity management |
| [aws/domain](./aws/domain) | Deploys AWS domain resources |
| [aws/emails](./aws/emails) | Deploys AWS SES resources for emails management, including domain validation |
| [aws/functions-app](./aws/functions-app) | Deploys AWS Lambda functions resources, including multi-triggers management and data storage |
| [aws/identity-center](./aws/identity-center) | Deploys AWS IAM Identity Center, to manage cross-accounts permissions via SSO |
| [aws/landing-zones](./aws/landing-zones) | Deploys AWS landing zones, to architect AWS organizations and accounts |
| [aws/management](./aws/management) | Deploys AWS global management resources, to help manage an AWS organization with a management account |
| [aws/static-web-app](./aws/static-web-app) | Deploys AWS CloudFront to expose a Static Web App, with routing policies for APIs |
| [aws/tf-backend](./aws/tf-backend) | Deploys AWS resources to manage a Terraform backend |
| [github/identity-provider](./github/identity-provider) | Registers GitHub in AWS with OIDC |
| [github/organization](./github/organization) | Deploys GitHub organization resources |
| [github/repository](./github/repository) | Deploys a GitHub repository |

## Usage

`amilochau/tf-modules` is proposed as Terraform modules. You can reference them using [generic Git source](https://developer.hashicorp.com/terraform/language/modules/sources#generic-git-repository):

```hcl
module "functions_app" {
  source      = "git::https://github.com/amilochau/tf-modules.git//aws/functions-app?ref=v1"

  # Settings - omitted here
}
```

Note that the `ref=v1` indicates which reference of the current repository you want to work with. Use the strategy that fits your use case:
- `ref=v1.0.0` (or `ref=COMMIT_SHA`): you benefit for stability, but you don't get latest features, bugfixes and security fixes
- `ref=v1`: you use the latest features of the major version you indicate; you don't suffer from breaking changes, but infrastructure changes can usually be seen with new features and fixes
- `ref=main`: you always use the latest features, even if they are not released; you may encounter breaking changes and bugs - use it only for quick prototypes

---

### Run manually

These commands can help you run the Terraform modules manually, thanks to `terraform` CLI:

- `terraform init`: initializes Terraform current module
- `terraform get`: gets latest version of the module
- `terraform workspace list`: lists available workspaces
- `terraform workspace new WORKSPACE_NAME`: creates a new workspace (as `dev`, `prd`, `shd`)
- `terraform workspace set WORKSPACE_NAME`: sets the current workspace
- `terraform plan -var-file="hosts/HOST_NAME.tfvars"`: plans the deployment of a specific host
- `terraform apply -var-file="hosts/HOST_NAME.tfvars"`: applies the deployment of a specific host

--- 

## Contribute

Feel free to push your code if you agree with publishing under the [MIT license](./LICENSE).
