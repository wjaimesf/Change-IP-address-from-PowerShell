
# Get content from settings.xml
[xml]$ConfigFile = Get-Content "$PSScriptRoot\settings.xml"

# TODO: Needs a way to prompt user for which network scheme in settings.xml
$Profile = "Net_1"
$IPType = "IPv4"

$ipsettings = @{
    IP = $ConfigFile.$IPType.$Profile.IP
    MaskBits = $ConfigFile.$IPType.$Profile.MaskBits
    Gateway = $ConfigFile.$IPType.$Profile.Gateway
    DNS = $ConfigFile.$IPType.$Profile.DNS
    }
$ipsettings


# TODO: Need to change this to choices and user input for which adapter to apply settings.
# Temporarily select network adapter that is UP.
$adapter = Get-NetAdapter | ? {$_.Status -eq "up"}

# Remove any existing IP, gateway from our ipv4 adapter
If (($adapter | Get-NetIPConfiguration).IPv4Address.IPAddress) {
    $adapter | Remove-NetIPAddress -AddressFamily $IPType -Confirm:$false
}

If (($adapter | Get-NetIPConfiguration).Ipv4DefaultGateway) {
    $adapter | Remove-NetRoute -AddressFamily $IPType -Confirm:$false
}

 # Configure the IP address and default gateway
$adapter | New-NetIPAddress `
    -AddressFamily $IPType `
    -IPAddress $ipsettings.IP `
    -PrefixLength $ipsettings.MaskBits `
    -DefaultGateway $ipsettings.Gateway

# Configure the DNS client server IP addresses
$adapter | Set-DnsClientServerAddress -ServerAddresses $ipsettings.DNS



# SETTING FOR DHCP

# TODO: Have user selection for DHCP
$IPType = "IPv4"
$adapter = Get-NetAdapter | ? {$_.Status -eq "up"}
$interface = $adapter | Get-NetIPInterface -AddressFamily $IPType

If ($interface.Dhcp -eq "Disabled") {
    # Remove existing gateway
    If (($interface | Get-NetIPConfiguration).Ipv4DefaultGateway) {
        $interface | Remove-NetRoute -Confirm:$false
    }

    # Enable DHCP
    $interface | Set-NetIPInterface -DHCP Enabled

    # Configure the  DNS Servers automatically
    $interface | Set-DnsClientServerAddress -ResetServerAddresses
}