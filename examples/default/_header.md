# Default example

This deploys the module in its simplest form.

The example requires Terraform 1.16 or later because it uses the ModTM-free
Log Analytics Workspace module 0.6.0. Its `parent_id` input receives the existing
resource group's ID. For an existing deployment of this example, follow the
[Workspace 0.6.0 upgrade instructions](https://github.com/Azure/terraform-azurerm-avm-res-operationalinsights-workspace/tree/v0.6.0#upgrading-from-05x-or-earlier)
before applying; the dependency now manages the workspace through AzAPI.
