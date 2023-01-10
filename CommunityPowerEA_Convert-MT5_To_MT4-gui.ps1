# Script to Convert Setting File from MT5 to MT4 for Community Power EA
# Drag and Drop file in Windows Forms and press button
#
# Autor: Ulises Cune (@Ulises2k)
# v1.8
#
#
#######################CONSOLE################################################################
Function Get-IniFile {
    Param(
        [string]$file
    )
    $ini = [ordered]@{}
    switch -regex -file $file {
        "^\s*(.+?)\s*=\s*(.*)$" {
            $name, $value = $matches[1..2]
            # skip comments that start with semicolon:
            if (!($name.StartsWith(";"))) {
                if ($value.Contains('||') ) {
                    $ini[$name] = $value.Split('||')[0]
                    continue
                }
                else {
                    $ini[$name] = $value
                    continue
                }
            }
        }
    }
    $ini
}

Function ConvertINItoProfileVersion {
    Param(
        [string]$FilePath
    )
    $content = Get-Content $FilePath
    switch -regex -file $FilePath {
        "^\s*(.+?)\s*=\s*(.*)$" {
            $name, $value = $matches[1..2]
            # skip comments that start with semicolon:
            if (!($name.StartsWith(";"))) {
                if ($value.Contains('||') ) {
                    $content = $content -replace "^$($name)\s*=(.*)", "$($name)=$($value.Split('||')[0])"
                }
                else {
                    $content = $content -replace "^$($name)\s*=(.*)", "$($name)=$($value)"
                }
            }
        }
    }
    $content | Set-Content $FilePath
}

function Set-OrAddIniValue {
    Param(
        [string]$FilePath,
        [hashtable]$keyValueList
    )
    $content = Get-Content $FilePath
    $keyValueList.GetEnumerator() | ForEach-Object {
        if ($content -match "^$($_.Key)\s*=") {
            $content = $content -replace "^$($_.Key)\s*=(.*)", "$($_.Key)=$($_.Value)"
        }
        else {
            $content += "$($_.Key)=$($_.Value)"
        }
    }
    $content | Set-Content $FilePath
}

function ConvertTFMT5toMT4 {
    Param(
        [string]$value,
        [string]$file
    )
    $inifile = Get-IniFile($file)
    $rvalue = [int]$inifile[$value]
    #MT5 TimeFrame are not in MT4
    #2 Minutes
    #3 Minutes
    #4 Minutes
    #6 Minutes
    #10 Minutes
    #12 Minutes
    #20 Minutes
    #2 Hours => 16386
    #3 Hours => 16387
    #6 Hours => 16390
    #8 Hours => 16392
    #12 Hours => 16396
    $TimeFrameMT5 = @(2, 3, 4, 6, 10, 12, 20, 16386, 16387, 16390, 16392, 16396)

    if ($TimeFrameMT5.Contains($rvalue)) {
        return [bool]$false
    }

    #1 Hour
    if ($rvalue -eq 16385) {
        Set-OrAddIniValue -FilePath $file -keyValueList @{
            $value = "60"
        }
    }

    #4 Hour
    if ($rvalue -eq 16388) {
        Set-OrAddIniValue -FilePath $file -keyValueList @{
            $value = "240"
        }
    }

    #1 Day
    if ($rvalue -eq 16408) {
        Set-OrAddIniValue -FilePath $file -keyValueList @{
            $value = "1440"
        }
    }

    #1 Week - Signal_TimeFrame= 32769 -> 10080
    if ($rvalue -eq 32769) {
        Set-OrAddIniValue -FilePath $file -keyValueList @{
            $value = "10080"
        }
    }

    #1 Month - Signal_TimeFrame= 49153 -> 43200
    if ($rvalue -eq 49153) {
        Set-OrAddIniValue -FilePath $file -keyValueList @{
            $value = "43200"
        }
    }

    return [bool]$true

}

function ConvertPriceMT5toMT4 {
    Param(
        [string]$value,
        [string]$file
    )
    #Close Price = 1 => 0
    #Open Price = 2 => 1
    #High Price = 3 => 2
    #Low Price = 4 => 3
    #Median Price = 5 => 4
    #Tipical Price = 6 => 5
    #Weighted Price = 7 => 6
    $inifile = Get-IniFile($file)
    $rvalue = [int]$inifile[$value]
    $rvalue = $rvalue - 1
    Set-OrAddIniValue -FilePath $file -keyValueList @{
        $value = [string]$rvalue
    }
}

#Profile settings use true/false. Tester setting use 1/0. I convert to profile for default
function ConvertBoolMT5toMT4 {
    Param(
        [string]$value,
        [string]$file
    )
    $inifile = Get-IniFile($file)

    if ([string]$inifile[$value] -eq "0") {
        Set-OrAddIniValue -FilePath $file -keyValueList @{
            $value = "false"
        }
    }

    if ([string]$inifile[$value] -eq "1") {
        Set-OrAddIniValue -FilePath $file -keyValueList @{
            $value = "true"
        }
    }
}

function MainConvert2MT4 {
    Param(
        [string]$filePath
    )
	
    $Destino = (Get-Item $filePath).BaseName + "-MT4.set"
    $CurrentDir = Split-Path -Path "$filePath"
    Copy-Item "$filePath" -Destination "$CurrentDir\$Destino"
	
	if(!(Test-Path -Path "$CurrentDir\$Destino")){
		return [bool]$false, 'Cant copy file. Reduce the PATH: $CurrentDir . Move the file, for example to C:\temp'
	}

    $Destino = "$CurrentDir\$Destino"
    ConvertINItoProfileVersion -FilePath $Destino

    #Convert TimeFrame
	if (!(ConvertTFMT5toMT4 -value "Signal_TimeFrame" -file $Destino)) {
		return [bool]$false, 'Signal_TimeFrame'
	}
	if (!(ConvertTFMT5toMT4 -value "VolPV_TF" -file $Destino)) {
		return [bool]$false, 'VolPV_TF'
	}
	if (!(ConvertTFMT5toMT4 -value "BigCandle_TF" -file $Destino)) {
		return [bool]$false, 'BigCandle_TF'
	}
	if (!(ConvertTFMT5toMT4 -value "Oscillators_TF" -file $Destino)) {
		return [bool]$false, 'Oscillators_TF'
	}
	if (!(ConvertTFMT5toMT4 -value "Oscillator2_TF" -file $Destino)) {
		return [bool]$false, 'Oscillator2_TF'
	}
	if (!(ConvertTFMT5toMT4 -value "Oscillator3_TF" -file $Destino)) {
		return [bool]$false, 'Oscillator3_TF'
	}
	if (!(ConvertTFMT5toMT4 -value "IdentifyTrend_TF" -file $Destino)) {
		return [bool]$false, 'IdentifyTrend_TF'
	}
	if (!(ConvertTFMT5toMT4 -value "TDI_TF" -file $Destino)) {
		return [bool]$false, 'TDI_TF'
	}
	if (!(ConvertTFMT5toMT4 -value "MACD_TF" -file $Destino)) {
		return [bool]$false, 'MACD_TF'
	}
	if (!(ConvertTFMT5toMT4 -value "MACD2_TF" -file $Destino)) {
		return [bool]$false, 'MACD2_TF'
	}
	if (!(ConvertTFMT5toMT4 -value "ADX_TF" -file $Destino)) {
		return [bool]$false, 'ADX_TF'
	}
	if (!(ConvertTFMT5toMT4 -value "DTrend_TF" -file $Destino)) {
		return [bool]$false, 'DTrend_TF'
	}
	if (!(ConvertTFMT5toMT4 -value "PSar_TF" -file $Destino)) {
		return [bool]$false, 'PSar_TF'
	}
	if (!(ConvertTFMT5toMT4 -value "MA_Filter_1_TF" -file $Destino)) {
		return [bool]$false, 'MA_Filter_1_TF'
	}
	if (!(ConvertTFMT5toMT4 -value "MA_Filter_2_TF" -file $Destino)) {
		return [bool]$false, 'MA_Filter_2_TF'
	}
	if (!(ConvertTFMT5toMT4 -value "MA_Filter_3_TF" -file $Destino)) {
		return [bool]$false, 'MA_Filter_3_TF'
	}
	if (!(ConvertTFMT5toMT4 -value "ZZ_TF" -file $Destino)) {
		return [bool]$false, 'ZZ_TF'
	}
	if (!(ConvertTFMT5toMT4 -value "VolMA_TF" -file $Destino)) {
		return [bool]$false, 'VolMA_TF'
	}
	if (!(ConvertTFMT5toMT4 -value "VolFilter_TF" -file $Destino)) {
		return [bool]$false, 'VolFilter_TF'
	}
	if (!(ConvertTFMT5toMT4 -value "FIBO_TF" -file $Destino)) {
		return [bool]$false, 'FIBO_TF'
	}
	if (!(ConvertTFMT5toMT4 -value "FIB2_TF" -file $Destino)) {
		return [bool]$false, 'FIB2_TF'
	}
	if (!(ConvertTFMT5toMT4 -value "CustomIndy1_TF" -file $Destino)) {
		return [bool]$false, 'CustomIndy1_TF'
	}
	if (!(ConvertTFMT5toMT4 -value "CustomIndy2_TF" -file $Destino)) {
		return [bool]$false, 'CustomIndy2_TF'
	}
	 
	#Convert Price
	ConvertPriceMT5toMT4 -value "Oscillators_Price" -file $Destino
	ConvertPriceMT5toMT4 -value "Oscillator2_Price" -file $Destino
	ConvertPriceMT5toMT4 -value "Oscillator3_Price" -file $Destino
	ConvertPriceMT5toMT4 -value "IdentifyTrend_AppliedPrice" -file $Destino
	ConvertPriceMT5toMT4 -value "TDI_AppliedPriceRSI" -file $Destino
	ConvertPriceMT5toMT4 -value "MACD_Price" -file $Destino
	ConvertPriceMT5toMT4 -value "MACD2_Price" -file $Destino
	ConvertPriceMT5toMT4 -value "MA_Filter_1_Price" -file $Destino
	ConvertPriceMT5toMT4 -value "MA_Filter_2_Price" -file $Destino
	ConvertPriceMT5toMT4 -value "MA_Filter_3_Price" -file $Destino
	Set-OrAddIniValue -FilePath $Destino  -keyValueList @{
		ADX_Price = "0"
	}
	 
	#Convert Bool (true/false)
	ConvertBoolMT5toMT4 -value "ShowVirtualInfoOnChart" -file $Destino
	ConvertBoolMT5toMT4 -value "ManageManual" -file $Destino
	ConvertBoolMT5toMT4 -value "RiskPerCurrency_UseSemaphor" -file $Destino
	ConvertBoolMT5toMT4 -value "GlobalAccountStopTillTomorrow" -file $Destino
	ConvertBoolMT5toMT4 -value "VolPV_FixOn1stPosOpen" -file $Destino
	ConvertBoolMT5toMT4 -value "Pending_DisableForOpposite" -file $Destino
	ConvertBoolMT5toMT4 -value "Pending_DeleteIfOpposite" -file $Destino
	ConvertBoolMT5toMT4 -value "GlobalTakeProfit_OnlyLock" -file $Destino
	ConvertBoolMT5toMT4 -value "UseVirtualTP" -file $Destino
	ConvertBoolMT5toMT4 -value "MartingailOnTheBarEnd" -file $Destino
	ConvertBoolMT5toMT4 -value "ApplyAfterClosedLoss" -file $Destino
	ConvertBoolMT5toMT4 -value "AntiMartingail_AllowTP" -file $Destino
	ConvertBoolMT5toMT4 -value "AllowBothMartinAndAntiMartin" -file $Destino
	ConvertBoolMT5toMT4 -value "PartialClose_AnyToAny" -file $Destino
	ConvertBoolMT5toMT4 -value "PartialClose_CloseProfitItself" -file $Destino
	ConvertBoolMT5toMT4 -value "PartialCloseHedge_MainToMain" -file $Destino
	ConvertBoolMT5toMT4 -value "PartialCloseHedge_BothWays" -file $Destino
	ConvertBoolMT5toMT4 -value "Oscillators_ContrTrend" -file $Destino
	ConvertBoolMT5toMT4 -value "Oscillator2_ContrTrend" -file $Destino
	ConvertBoolMT5toMT4 -value "Oscillator3_ContrTrend" -file $Destino
	ConvertBoolMT5toMT4 -value "IdentifyTrend_Reverse" -file $Destino
	ConvertBoolMT5toMT4 -value "IdentifyTrend_UseClosedBars" -file $Destino
	ConvertBoolMT5toMT4 -value "TDI_Reverse" -file $Destino
	ConvertBoolMT5toMT4 -value "MACD_Reverse" -file $Destino
	ConvertBoolMT5toMT4 -value "MACD2_Reverse" -file $Destino
	ConvertBoolMT5toMT4 -value "ADX_Reverse" -file $Destino
	ConvertBoolMT5toMT4 -value "DTrend_Reverse" -file $Destino
	ConvertBoolMT5toMT4 -value "DTrend_UseClosedBars" -file $Destino
	ConvertBoolMT5toMT4 -value "PSar_Reverse" -file $Destino
	ConvertBoolMT5toMT4 -value "ZZ_UsePrevExtremums" -file $Destino
	ConvertBoolMT5toMT4 -value "ZZ_Reverse" -file $Destino
	ConvertBoolMT5toMT4 -value "ZZ_UseClosedBars" -file $Destino
	ConvertBoolMT5toMT4 -value "ZZ_FillRectangle" -file $Destino
	ConvertBoolMT5toMT4 -value "CustomIndy1_Reverse" -file $Destino
	ConvertBoolMT5toMT4 -value "CustomIndy2_Reverse" -file $Destino
	ConvertBoolMT5toMT4 -value "CustomIndy2_DrawInSubwindow" -file $Destino
	ConvertBoolMT5toMT4 -value "Custom_Schedule_On" -file $Destino
	ConvertBoolMT5toMT4 -value "News_Impact_L" -file $Destino
	ConvertBoolMT5toMT4 -value "News_Impact_N" -file $Destino
	ConvertBoolMT5toMT4 -value "Profit_ShowInPercents" -file $Destino
	ConvertBoolMT5toMT4 -value "Alerts_Enabled" -file $Destino
	ConvertBoolMT5toMT4 -value "Sounds_Enabled" -file $Destino
	ConvertBoolMT5toMT4 -value "SaveVirtualStateOnEveryChange" -file $Destino
	ConvertBoolMT5toMT4 -value "SendAlertsToGrammy" -file $Destino
	ConvertBoolMT5toMT4 -value "NewDealOnNewBar" -file $Destino
	ConvertBoolMT5toMT4 -value "AllowHedge" -file $Destino
	ConvertBoolMT5toMT4 -value "CL_CloseOnProfitAndDD" -file $Destino
	ConvertBoolMT5toMT4 -value "Pending_CancelOnOpposite" -file $Destino
	ConvertBoolMT5toMT4 -value "UseVirtualSL" -file $Destino
	ConvertBoolMT5toMT4 -value "UseOnlyOpenedTrades" -file $Destino
	ConvertBoolMT5toMT4 -value "BigCandle_CurrentBar" -file $Destino
	ConvertBoolMT5toMT4 -value "Oscillators_UseClosedBars" -file $Destino
	ConvertBoolMT5toMT4 -value "Oscillator2_UseClosedBars" -file $Destino
	ConvertBoolMT5toMT4 -value "Oscillator3_UseClosedBars" -file $Destino
	ConvertBoolMT5toMT4 -value "IdentifyTrend_Enable" -file $Destino
	ConvertBoolMT5toMT4 -value "TDI_UseClosedBars" -file $Destino
	ConvertBoolMT5toMT4 -value "MACD_UseClosedBars" -file $Destino
	ConvertBoolMT5toMT4 -value "MACD2_UseClosedBars" -file $Destino
	ConvertBoolMT5toMT4 -value "ADX_UseClosedBars" -file $Destino
	ConvertBoolMT5toMT4 -value "ZZ_VisualizeLevels" -file $Destino
	ConvertBoolMT5toMT4 -value "FIBO_UseClosedBars" -file $Destino
	ConvertBoolMT5toMT4 -value "FIB2_UseClosedBars" -file $Destino
	ConvertBoolMT5toMT4 -value "CustomIndy1_UseClosedBars" -file $Destino
	ConvertBoolMT5toMT4 -value "CustomIndy1_DrawInSubwindow" -file $Destino
	ConvertBoolMT5toMT4 -value "CustomIndy1_AllowNegativeAndZero" -file $Destino
	ConvertBoolMT5toMT4 -value "CustomIndy2_UseClosedBars" -file $Destino
	ConvertBoolMT5toMT4 -value "CustomIndy2_AllowNegativeAndZero" -file $Destino
	ConvertBoolMT5toMT4 -value "Spread_ApplyToFirst" -file $Destino
	ConvertBoolMT5toMT4 -value "Spread_ApplyToMartin" -file $Destino
	ConvertBoolMT5toMT4 -value "News_Impact_H" -file $Destino
	ConvertBoolMT5toMT4 -value "News_Impact_M" -file $Destino
	ConvertBoolMT5toMT4 -value "News_ShowOnChart" -file $Destino
	ConvertBoolMT5toMT4 -value "Lines_AllowDragging" -file $Destino
	ConvertBoolMT5toMT4 -value "GUI_Enabled" -file $Destino
	ConvertBoolMT5toMT4 -value "GUI_ShowSignals" -file $Destino
	ConvertBoolMT5toMT4 -value "Show_Closed" -file $Destino
	ConvertBoolMT5toMT4 -value "Show_Pending" -file $Destino
	ConvertBoolMT5toMT4 -value "Profit_ShowInMoney" -file $Destino
	ConvertBoolMT5toMT4 -value "Profit_ShowInPoints" -file $Destino
	ConvertBoolMT5toMT4 -value "Profit_Aggregate" -file $Destino
	ConvertBoolMT5toMT4 -value "SL_TP_Dashes_Show" -file $Destino
	ConvertBoolMT5toMT4 -value "MessagesToGrammy" -file $Destino


    return [bool]$true
}

#######################GUI################################################################
### API Windows Forms ###
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")

### Create form ###
$form = New-Object System.Windows.Forms.Form
$form.Text = "Convert from MT5 to MT4 - CommunityPower EA"
$form.Size = '800,320'
$form.StartPosition = "CenterScreen"
$form.MinimumSize = $form.Size
$form.MaximizeBox = $False
$form.Topmost = $True

### Define controls ###
# Button
$button = New-Object System.Windows.Forms.Button
$button.Location = '5,5'
$button.Size = '120,23'
$button.Text = "Convert to MT4"

# Button
$button2 = New-Object System.Windows.Forms.Button
$button2.Location = '5,30'
$button2.Size = '75,23'
$button2.Text = "Clear"

# Label
$label = New-Object System.Windows.Forms.Label
$label.Location = '5,60'
$label.AutoSize = $True
$label.Text = "Drag and Drop MT5 files settings here:"

# Listbox
$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = '5,80'
$listBox.Size = '760,180'
$listBox.Anchor = ([System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right -bor [System.Windows.Forms.AnchorStyles]::Top)
$listBox.IntegralHeight = $False
$listBox.AllowDrop = $True

# Status Bar
$statusBar = New-Object System.Windows.Forms.StatusBar
$statusBar.Text = "Ready"

### Add controls to form ###
$form.SuspendLayout()
$form.Controls.Add($button)
$form.Controls.Add($button2)
$form.Controls.Add($label)
$form.Controls.Add($listBox)
$form.Controls.Add($statusBar)
$form.ResumeLayout()

### Write event handlers ###
$button_Click = {
    foreach ($item in $listBox.Items) {
        $i = Get-Item -LiteralPath $item
        if (!($i -is [System.IO.DirectoryInfo])) {
            $status, $TF = MainConvert2MT4 -file $item
            if ($status) {
                [System.Windows.Forms.MessageBox]::Show('Successfully convert MT5 to MT4 Community Power EA', 'Convert from MT5 to MT4', 0, 64)
                $statusBar.Text = "Successfully"
            }
            else {
                [System.Windows.Forms.MessageBox]::Show('ERROR. ' + $TF , 'Convert from MT5 to MT4', 0, 16)
                $statusBar.Text = "ERROR." + $TF
            }
        }
    }
}

$button2_Click = {
    $listBox.Items.Clear()
    $statusBar.Text = ""
}

$listBox_DragOver = [System.Windows.Forms.DragEventHandler] {
    if ($_.Data.GetDataPresent([Windows.Forms.DataFormats]::FileDrop)) {
        $_.Effect = 'Copy'
    }
    else {
        $_.Effect = 'None'
    }
}

$listBox_DragDrop = [System.Windows.Forms.DragEventHandler] {
    foreach ($filename in $_.Data.GetData([Windows.Forms.DataFormats]::FileDrop)) {
        $listBox.Items.Add($filename)
    }
    $statusBar.Text = ("List contains $($listBox.Items.Count) items")
}

### Wire up events ###
$button.Add_Click($button_Click)
$button2.Add_Click($button2_Click)
$listBox.Add_DragOver($listBox_DragOver)
$listBox.Add_DragDrop($listBox_DragDrop)

#### Show form ###
[void] $form.ShowDialog()
