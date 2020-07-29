$BasePath = "F:\ECS\Service\Lanzendorf\Technik\Auftraege\9.3108_steyrermuehl\schriftverkehr\dokumente"
$AclObjects = Get-ChildItem $BasePath
.\privs.ps1 -Privilege SeTakeOwnershipPrivilege
ForEach ( $Object in $AclObjects ) {
    $acl = Get-Acl $Object.FullName
    $acl.SetOwner([System.Security.Principal.NTAccount]::new('Administrators'))
    $rule = [System.Security.AccessControl.FileSystemAccessRule]::new('Administrators', 'FullControl', 'None', 'None', 'Allow')
    $acl.AddAccessRule($rule)
    Set-Acl $Object.FullName $acl
}