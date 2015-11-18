function New-TemporaryDirectory
{
	[CmdletBinding(SupportsShouldProcess=$true)]
	param (
		[ValidateNotNullOrEmpty()]
		[string]$Name="temporary-drive-*",

		[ValidateNotNullOrEmpty()]
		[string]$Description=""
	)

	if ([string]::IsNullOrEmpty($Name))
	{
		$Name = (Get-Date -Format o) -replace ":","."
	}
	
	$temporaryFolderDriveCount = ((Get-PSDrive -Scope Global | Where-Object { $_.Name -like $Name}).Count + 1)
	$Name = $Name -replace "\*",$temporaryFolderDriveCount
	$temporaryDriveName = $Name
	$temporaryFolderPath = Join-Path -Path $ENV:temp -ChildPath $Name

	$descriptionCreationDate = Get-Date -Format s
	$Description += "- created on ${descriptionCreationDate} by the New-TemporaryDirectory cmdlet "
	$psDriveDescription = $Description + "for easy access to [${temporaryFolderPath}]"

	$properties = @{
		Name = $Name;
		FullName = $temporaryFolderPath;
		PSDrive = $temporaryDriveName;
		FolderExists = $false;
		PSDriveExists = $false;
		Exists = $false;
		CreationTime = "";
		Description = $Description;
		LocationWhenCreated = (Get-Location).Path;
	}

	try
	{
		$folderObject = New-Item -Path $temporaryFolderPath -ItemType Directory
		$properties.FolderExists = $folderObject.Exists
		$properties.CreationTime = $folderObject.CreationTime

		$psDriveObject = New-PSDrive -Name $temporaryDriveName -PSProvider FileSystem -Root $temporaryFolderPath -Scope Global -Description $psDriveDescription
		$properties.PSDriveExists = $true
	}
	catch
	{
		Write-Error -Message "The creation process failed because a temporary directory or PSDrive already exists by the name [${temporaryFolderPath}]"
	}

	$properties.Exists = ($properties.FolderExists -and $properties.PSDriveExists)

	$temporaryDirectoryObject = New-Object -TypeName PSObject -Property $properties

	$objectMethod = { if ($this.Exists) { return ($this.PSDrive + ":\") } }
	Add-Member -InputObject $temporaryDirectoryObject -Name GetDrivePath -MemberType ScriptMethod -Value $objectMethod

	$objectMethod = { if ($this.Exists) { return ($this.FullName) } }
	Add-Member -InputObject $temporaryDirectoryObject -Name GetFolderPath -MemberType ScriptMethod -Value $objectMethod

	$objectMethod = { if ($this.Exists) {Set-Location -Path ($this.PSDrive + ":\")} }
	Add-Member -InputObject $temporaryDirectoryObject -Name GotoFolderLocation -MemberType ScriptMethod -Value $objectMethod

	$objectMethod = { Set-Location -Path $this.LocationWhenCreated }
	Add-Member -InputObject $temporaryDirectoryObject -Name GotoLocationWhenCreated -MemberType ScriptMethod -Value $objectMethod

	Write-Output -InputObject $temporaryDirectoryObject
}