# atomic-cookbook

TODO: Enter the cookbook description here.

## Supported Platforms

TODO: List your supported platforms.

## Attributes

<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['atomic']['bacon']</tt></td>
    <td>Boolean</td>
    <td>whether to include bacon</td>
    <td><tt>true</tt></td>
  </tr>
</table>

## Usage

### atomic::default

Include `atomic` in your node's `run_list`:

```json
{
  "run_list": [
    "recipe[atomic::default]"
  ]
}
```

## License and Authors

Author:: Chef Partner Engineering (<partnereng@chef.io>)
