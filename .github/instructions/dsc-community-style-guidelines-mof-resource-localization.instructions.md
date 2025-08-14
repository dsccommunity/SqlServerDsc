---
description: Guidelines for implementing localization for MOF DSC resources.
applyTo: "source/DSCResources/**/*.psm1,source/DSCResources/**/*.strings.psd1"
---

# MOF Desired State Configuration (DSC) Resource Localization

## File Structure
- Create `en-US` folder in each resource directory
- Name strings file: `DSC_<ResourceName>.strings.psd1`
- Use names returned from `Get-UICulture` for additional language folder names
