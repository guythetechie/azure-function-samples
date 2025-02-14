@export()
func getPrefix(applicationName string, resourceGroupId string) string =>
  '${applicationName}-${take(uniqueString(resourceGroupId), 4)}'
@export()
func getResourceGroupName(resourceId string) string => split(resourceId, '/')[4]
@export()
func getResourceName(resourceId string) string => last(split(resourceId, '/'))
@export()
func getResourceParentName(resourceId string) string => split(resourceId, '/')[length(split(resourceId, '/')) - 2]
@export()
func getResourceParentId(resourceId string) string =>
  join(take(split(resourceId, '/'), length(split(resourceId, '/')) - 2), '/')
