#!/usr/bin/env pwsh
# IP地址检测测试脚本

function Write-ColorText {
    param($Text, $Color = "White")
    Write-Host $Text -ForegroundColor $Color
}

function Show-Header {
    Write-ColorText "`n🔍 IP地址检测测试" "Green"
    Write-ColorText "====================" "Green"
    Write-ColorText ""
}

function Test-DefaultGateway {
    Write-ColorText "🎯 方法1: 通过默认网关检测..." "Yellow"
    
    try {
        $result = route print 0.0.0.0 2>$null
        $lines = $result -split "`n"
        
        foreach ($line in $lines) {
            if ($line -match "0\.0\.0\.0.*0\.0\.0\.0") {
                $parts = $line.Trim() -split "\s+"
                if ($parts.Length -ge 4) {
                    $localIP = $parts[3]
                    if ($localIP -match "^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$") {
                        if ($localIP.StartsWith("192.168.") -or $localIP.StartsWith("10.") -or 
                            ($localIP.StartsWith("172.") -and [int]($localIP.Split('.')[1]) -ge 16 -and [int]($localIP.Split('.')[1]) -le 31)) {
                            Write-ColorText "✅ 检测到真实IP: $localIP" "Green"
                            return $localIP
                        }
                    }
                }
            }
        }
    } catch {
        Write-ColorText "❌ 默认网关检测失败: $($_.Exception.Message)" "Red"
    }
    
    Write-ColorText "⚠️  默认网关方法未找到有效IP" "Yellow"
    return $null
}

function Test-NetworkInterfaces {
    Write-ColorText "`n🌐 方法2: 通过网络接口检测..." "Yellow"
    
    # VPN和虚拟网卡关键词
    $vpnKeywords = @(
        'tap', 'tun', 'vpn', 'virtual', 'vmware', 'vbox', 'hyper-v', 
        'docker', 'wsl', 'loopback', 'teredo', 'isatap', 'pptp', 
        'openvpn', 'wireguard', 'nordvpn', 'expressvpn', 'clash',
        'wintun', 'utun', 'cscotun'
    )
    
    # 物理网卡关键词
    $physicalKeywords = @(
        'ethernet', 'wi-fi', 'wireless', 'wlan', 'lan', 'realtek', 
        'intel', 'broadcom', 'qualcomm', 'atheros'
    )
    
    $physicalIPs = @()
    $virtualIPs = @()
    
    Write-ColorText "📋 所有网络接口:" "Cyan"
    
    Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
        $_.InterfaceAlias -ne "Loopback Pseudo-Interface 1" -and 
        $_.IPAddress -ne "127.0.0.1" 
    } | ForEach-Object {
        $interface = $_.InterfaceAlias
        $ip = $_.IPAddress
        $lowerName = $interface.ToLower()
        
        $isVirtual = $vpnKeywords | Where-Object { $lowerName.Contains($_) } | Measure-Object | Select-Object -ExpandProperty Count
        $isPhysical = $physicalKeywords | Where-Object { $lowerName.Contains($_) } | Measure-Object | Select-Object -ExpandProperty Count
        
        $isPrivateIP = $ip.StartsWith("192.168.") -or $ip.StartsWith("10.") -or 
                      ($ip.StartsWith("172.") -and [int]($ip.Split('.')[1]) -ge 16 -and [int]($ip.Split('.')[1]) -le 31)
        
        if ($isPrivateIP) {
            if ($isPhysical -gt 0 -or $isVirtual -eq 0) {
                Write-ColorText "  ✅ 物理网卡: $interface -> $ip" "Green"
                $physicalIPs += @{ Interface = $interface; IP = $ip }
            } else {
                Write-ColorText "  ⚠️  虚拟网卡: $interface -> $ip" "Yellow"
                $virtualIPs += @{ Interface = $interface; IP = $ip }
            }
        } else {
            Write-ColorText "  ❌ 非局域网: $interface -> $ip" "Red"
        }
    }
    
    if ($physicalIPs.Count -gt 0) {
        Write-ColorText "`n✅ 推荐使用物理网卡IP: $($physicalIPs[0].IP)" "Green"
        return $physicalIPs[0].IP
    } elseif ($virtualIPs.Count -gt 0) {
        Write-ColorText "`n⚠️  仅发现虚拟网卡IP: $($virtualIPs[0].IP)" "Yellow"
        return $virtualIPs[0].IP
    } else {
        Write-ColorText "`n❌ 未找到可用的局域网IP" "Red"
        return $null
    }
}

function Test-NodeServerDetection {
    Write-ColorText "`n🚀 方法3: Node.js服务器检测..." "Yellow"
    
    try {
        $output = node -e "
            const os = require('os');
            const { execSync } = require('child_process');
            
            function getIPByDefaultGateway() {
                try {
                    const result = execSync('route print 0.0.0.0', { encoding: 'utf8', timeout: 5000 });
                    const lines = result.split('\n');
                    
                    for (const line of lines) {
                        if (line.includes('0.0.0.0') && line.includes('0.0.0.0')) {
                            const parts = line.trim().split(/\s+/);
                            if (parts.length >= 4) {
                                const localIP = parts[3];
                                if (localIP && localIP.match(/^(\d{1,3}\.){3}\d{1,3}$/)) {
                                    if (localIP.startsWith('192.168.') || localIP.startsWith('10.') || 
                                        (localIP.startsWith('172.') && parseInt(localIP.split('.')[1]) >= 16 && parseInt(localIP.split('.')[1]) <= 31)) {
                                        return localIP;
                                    }
                                }
                            }
                        }
                    }
                } catch (error) {
                    console.log('Gateway detection failed:', error.message);
                }
                return null;
            }
            
            const gatewayIP = getIPByDefaultGateway();
            console.log(gatewayIP || 'null');
        "
        
        if ($output -and $output -ne "null") {
            Write-ColorText "✅ Node.js检测到IP: $output" "Green"
            return $output.Trim()
        } else {
            Write-ColorText "⚠️  Node.js未检测到有效IP" "Yellow"
            return $null
        }
    } catch {
        Write-ColorText "❌ Node.js检测失败: $($_.Exception.Message)" "Red"
        return $null
    }
}

function Show-Summary {
    param($GatewayIP, $InterfaceIP, $NodeIP)
    
    Write-ColorText "`n📊 检测结果总结:" "Cyan"
    Write-ColorText "═══════════════════" "Cyan"
    Write-ColorText "默认网关方法: $(if($GatewayIP) { $GatewayIP } else { '未检测到' })" "White"
    Write-ColorText "网络接口方法: $(if($InterfaceIP) { $InterfaceIP } else { '未检测到' })" "White"
    Write-ColorText "Node.js方法: $(if($NodeIP) { $NodeIP } else { '未检测到' })" "White"
    
    $recommendedIP = $NodeIP
    if (-not $recommendedIP) { $recommendedIP = $GatewayIP }
    if (-not $recommendedIP) { $recommendedIP = $InterfaceIP }
    
    if ($recommendedIP) {
        Write-ColorText "`n🎯 推荐使用IP: $recommendedIP" "Green"
        Write-ColorText "📱 微信小程序配置: $recommendedIP:3002" "Green"
    } else {
        Write-ColorText "`n❌ 未能检测到可用的IP地址" "Red"
    }
}

# 主执行流程
Show-Header

$gatewayIP = Test-DefaultGateway
$interfaceIP = Test-NetworkInterfaces  
$nodeIP = Test-NodeServerDetection

Show-Summary -GatewayIP $gatewayIP -InterfaceIP $interfaceIP -NodeIP $nodeIP

Write-ColorText "`n✨ 检测完成!" "Green"
