# Script to Convert Setting File from MT5 to MT4 for Community Power EA
# Drag and Drop file in Windows Forms and press button
#
# Autor: Ulises Cune (@Ulises2k)
# v1.0


#######################CONSOLE################################################################
Function Get-IniFile ($file) {
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

Function ConvertINItoProfileVersion ([string]$FilePath) {
    $content = Get-Content $FilePath
    switch -regex -file $FilePath {
        "^\s*(.+?)\s*=\s*(.*)$" {
            $name, $value = $matches[1..2]
            # skip comments that start with semicolon:
            if (!($name.StartsWith(";"))) {
                if ($value.Contains('||') ) {
                    $content = $content -replace "$($name)\s*=(.*)", "$($name)=$($value.Split('||')[0])"
                }
                else {
                    $content = $content -replace "$($name)\s*=(.*)", "$($name)=$($value)"
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
            $content = $content -replace "$($_.Key)\s*=(.*)", "$($_.Key)=$($_.Value)"
        }
        else {
            $content += "$($_.Key)=$($_.Value)"
        }
    }

    $content | Set-Content $FilePath
}


function ConvertTFMT5toMT4 ([string]$value , [string]$file) {
    $inifile = Get-IniFile($file)
    $rvalue = [int]$inifile[$value]

    #1 Hour
    if ($rvalue -eq 16385) {
        Set-OrAddIniValue -FilePath $file  -keyValueList @{
            $value = "60"
        }
    }

    #4 Hour
    if ($rvalue -eq 16388) {
        Set-OrAddIniValue -FilePath $file  -keyValueList @{
            $value = "240"
        }
    }

    #1 Day
    if ($rvalue -eq 16408) {
        Set-OrAddIniValue -FilePath $file  -keyValueList @{
            $value = "1440"
        }
    }

    #1 Week - Signal_TimeFrame=32769 -> 10080
    if ($rvalue -eq 32769) {
        Set-OrAddIniValue -FilePath $file  -keyValueList @{
            $value = "10080"
        }
    }

    #1 Month - Signal_TimeFrame= 49153 -> 43200
    if ($rvalue -eq 49153) {
        Set-OrAddIniValue -FilePath $file  -keyValueList @{
            $value = "43200"
        }
    }
}

function ConvertPriceMT5toMT4 ([string]$value, [string]$file) {
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
    Set-OrAddIniValue -FilePath $file  -keyValueList @{
        $value = [string]$rvalue
    }
}

#Profile settings use true/false. Tester setting use 1/0. I convert to profile for default
function ConvertBoolMT5toMT4 ([string]$value, [string]$file) {
    $inifile = Get-IniFile($file)
    if ([string]$inifile[$value] -eq "0") {
        Set-OrAddIniValue -FilePath $file  -keyValueList @{
            $value = "false"
        }
    }
    if ([string]$inifile[$value] -eq "1") {
        Set-OrAddIniValue -FilePath $file  -keyValueList @{
            $value = "true"
        }
    }
}

#Optional
function ReplaceDefaultsValueMT5toMT4 ([string]$file) {
    #My Defaults
    Set-OrAddIniValue -FilePath $file  -keyValueList @{
        MessagesToGrammy = "0"
        BE_Alert_After   = "0"
        GUI_Enabled      = "0"
        Alerts_Enabled   = "0"
        Sounds_Enabled   = "0"
        Show_Opened      = "1"
        Show_Closed      = "1"
        Show_Pending     = "1"
        MaxHistoryDeals  = "1"
        GUI_ShowSignals  = "1"
    }
}

function MainConvert2MT4 ([string]$filePath) {

    $Destino = (Get-Item $filePath).BaseName + "-MT4.set"
    $CurrentDir = Split-Path -Path "$filePath"
    Copy-Item "$filePath" -Destination "$CurrentDir\$Destino"

    $Destino = "$CurrentDir\$Destino"
    ConvertINItoProfileVersion -FilePath $Destino
    #ReplaceDefaultsValueMT5toMT4 -file "$Destino"

    #Convert TimeFrame
    ConvertTFMT5toMT4 -value "Signal_TimeFrame" -file $Destino
    ConvertTFMT5toMT4 -value "VolPV_TF" -file $Destino
    ConvertTFMT5toMT4 -value "BigCandle_TF" -file $Destino
    ConvertTFMT5toMT4 -value "Oscillator2_TF" -file $Destino
    ConvertTFMT5toMT4 -value "Oscillator3_TF" -file $Destino
    ConvertTFMT5toMT4 -value "IdentifyTrend_TF" -file $Destino
    ConvertTFMT5toMT4 -value "TDI_TF" -file $Destino
    ConvertTFMT5toMT4 -value "FIBO_TF" -file $Destino
    ConvertTFMT5toMT4 -value "FIB2_TF" -file $Destino
    ConvertTFMT5toMT4 -value "MACD_TF" -file $Destino
    ConvertTFMT5toMT4 -value "PSar_TF" -file $Destino
    ConvertTFMT5toMT4 -value "MA_Filter_1_TF" -file $Destino
    ConvertTFMT5toMT4 -value "MA_Filter_2_TF" -file $Destino
    ConvertTFMT5toMT4 -value "MA_Filter_3_TF" -file $Destino
    ConvertTFMT5toMT4 -value "ZZ_TF" -file $Destino
    ConvertTFMT5toMT4 -value "VolMA_TF" -file $Destino
    ConvertTFMT5toMT4 -value "VolFilter_TF" -file $Destino

    #Convert Price
    ConvertPriceMT5toMT4 -value "Oscillators_Price" -file $Destino
    ConvertPriceMT5toMT4 -value "Oscillator2_Price" -file $Destino
    ConvertPriceMT5toMT4 -value "Oscillator3_Price" -file $Destino
    ConvertPriceMT5toMT4 -value "IdentifyTrend_AppliedPrice" -file $Destino
    ConvertPriceMT5toMT4 -value "TDI_AppliedPriceRSI" -file $Destino
    ConvertPriceMT5toMT4 -value "MACD_Price" -file $Destino
    ConvertPriceMT5toMT4 -value "MA_Filter_1_Price" -file $Destino
    ConvertPriceMT5toMT4 -value "MA_Filter_2_Price" -file $Destino
    ConvertPriceMT5toMT4 -value "MA_Filter_3_Price" -file $Destino

    #; Expert properties
    ConvertBoolMT5toMT4 -value "NewDealOnNewBar" -file $Destino
    ConvertBoolMT5toMT4 -value "AllowHedge" -file $Destino
    ConvertBoolMT5toMT4 -value "ManageManual" -file $Destino
    #;Pending_CancelOnOpposite
    ConvertBoolMT5toMT4 -value "Pending_CancelOnOpposite" -file $Destino
    #; StopLoss properties
    ConvertBoolMT5toMT4 -value "UseVirtualSL" -file $Destino
    #; TakeProfit properties
    ConvertBoolMT5toMT4 -value "UseVirtualTP" -file $Destino
    #; Martingail properties
    ConvertBoolMT5toMT4 -value "MartingailOnTheBarEnd" -file $Destino
    ConvertBoolMT5toMT4 -value "ApplyAfterClosedLoss" -file $Destino
    #; Big candle properties
    ConvertBoolMT5toMT4 -value "BigCandle_CurrentBar" -file $Destino
    #; Oscillator #1 properties
    ConvertBoolMT5toMT4 -value "Oscillators_ContrTrend" -file $Destino
    #; Oscillator #2 properties
    ConvertBoolMT5toMT4 -value "Oscillator2_ContrTrend" -file $Destino
    #; Oscillator #3 properties
    ConvertBoolMT5toMT4 -value "Oscillator3_ContrTrend" -file $Destino
    #; IdentifyTrend properties
    ConvertBoolMT5toMT4 -value "IdentifyTrend_Enable" -file $Destino
    ConvertBoolMT5toMT4 -value "IdentifyTrend_Reverse" -file $Destino
    ConvertBoolMT5toMT4 -value "IdentifyTrend_UseClosedBars" -file $Destino
    #; TDI properties
    ConvertBoolMT5toMT4 -value "TDI_Reverse" -file $Destino
    ConvertBoolMT5toMT4 -value "TDI_UseClosedBars" -file $Destino
    #; MACD properties
    ConvertBoolMT5toMT4 -value "MACD_Reverse" -file $Destino
    ConvertBoolMT5toMT4 -value "MACD_UseClosedBars" -file $Destino
    #; Parabolic SAR properties
    ConvertBoolMT5toMT4 -value "PSar_Reverse" -file $Destino
    #; ZZ properties
    ConvertBoolMT5toMT4 -value "ZZ_UseClosedBars" -file $Destino
    #; FIBO #1 properties
    ConvertBoolMT5toMT4 -value "FIBO_UseClosedBars" -file $Destino
    #; FIBO #2 properties
    ConvertBoolMT5toMT4 -value "FIB2_UseClosedBars" -file $Destino
    #; Custom Schedule
    ConvertBoolMT5toMT4 -value "Custom_Schedule_On" -file $Destino
    #; News settings
    ConvertBoolMT5toMT4 -value "News_Impact_H" -file $Destino
    ConvertBoolMT5toMT4 -value "News_Impact_M" -file $Destino
    ConvertBoolMT5toMT4 -value "News_Impact_L" -file $Destino
    ConvertBoolMT5toMT4 -value "News_Impact_N" -file $Destino
    ConvertBoolMT5toMT4 -value "News_ShowOnChart" -file $Destino
    #; GUI settings
    ConvertBoolMT5toMT4 -value "GUI_Enabled" -file $Destino
    ConvertBoolMT5toMT4 -value "GUI_ShowSignals" -file $Destino
    #; Show orders
    ConvertBoolMT5toMT4 -value "Show_Closed" -file $Destino
    ConvertBoolMT5toMT4 -value "Show_Pending" -file $Destino
    ConvertBoolMT5toMT4 -value "Profit_ShowInMoney" -file $Destino
    ConvertBoolMT5toMT4 -value "Profit_ShowInPoints" -file $Destino
    ConvertBoolMT5toMT4 -value "Profit_ShowInPercents" -file $Destino
    ConvertBoolMT5toMT4 -value "Profit_Aggregate" -file $Destino
    ConvertBoolMT5toMT4 -value "SL_TP_Dashes_Show" -file $Destino
    #; Notifications settings
    ConvertBoolMT5toMT4 -value "MessagesToGrammy" -file $Destino
    ConvertBoolMT5toMT4 -value "Alerts_Enabled" -file $Destino
    ConvertBoolMT5toMT4 -value "Sounds_Enabled" -file $Destino

    Write-Output "Successfully Converted MT5 To MT4"
}


#######################GUI################################################################
### API Windows Forms ###
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")



### Create form ###
$form = New-Object System.Windows.Forms.Form
$form.Text = "Convert from MT5 to MT4 - CommunityPower EA"
$form.Size = '512,320'
$form.StartPosition = "CenterScreen"
$form.MinimumSize = $form.Size
$form.MaximizeBox = $False
$form.Topmost = $True


### Define controls ###
$button = New-Object System.Windows.Forms.Button
$button.Location = '5,5'
$button.Size = '75,23'
$button.Width = 120
$button.Text = "Convert to MT4"

$checkbox = New-Object Windows.Forms.Checkbox
$checkbox.Location = '140,8'
$checkbox.AutoSize = $True
$checkbox.Text = "Clear afterwards"

$label = New-Object Windows.Forms.Label
$label.Location = '5,40'
$label.AutoSize = $True
$label.Text = "Drag and Drop files settings MT5 here:"

$listBox = New-Object Windows.Forms.ListBox
$listBox.Location = '5,60'
$listBox.Height = 200
$listBox.Width = 480
$listBox.Anchor = ([System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right -bor [System.Windows.Forms.AnchorStyles]::Top)
$listBox.IntegralHeight = $False
$listBox.AllowDrop = $True

$statusBar = New-Object System.Windows.Forms.StatusBar
$statusBar.Text = "Ready"


### Add controls to form ###
$form.SuspendLayout()
$form.Controls.Add($button)
$form.Controls.Add($checkbox)
$form.Controls.Add($label)
$form.Controls.Add($listBox)
$form.Controls.Add($statusBar)
$form.ResumeLayout()


### Write event handlers ###
$button_Click = {
    foreach ($item in $listBox.Items) {
        if (!($i -is [System.IO.DirectoryInfo])) {
            MainConvert2MT4 -file $item
            [System.Windows.Forms.MessageBox]::Show('Successfully convert MT5 to MT4 Community Power EA', 'Convert from MT5 to MT4', 0, 64)
        }
    }

    if ($checkbox.Checked -eq $True) {
        $listBox.Items.Clear()
    }

    $statusBar.Text = ("List contains $($listBox.Items.Count) items")
}

$listBox_DragOver = [System.Windows.Forms.DragEventHandler] {
    if ($_.Data.GetDataPresent([Windows.Forms.DataFormats]::FileDrop)) {
        # $_ = [System.Windows.Forms.DragEventArgs]
        $_.Effect = 'Copy'
    }
    else {
        $_.Effect = 'None'
    }
}

$listBox_DragDrop = [System.Windows.Forms.DragEventHandler] {
    foreach ($filename in $_.Data.GetData([Windows.Forms.DataFormats]::FileDrop)) {
        # $_ = [System.Windows.Forms.DragEventArgs]
        $listBox.Items.Add($filename)
    }
    $statusBar.Text = ("List contains $($listBox.Items.Count) items")
}

$form_FormClosed = {
    try {
        $listBox.remove_Click($button_Click)
        $listBox.remove_DragOver($listBox_DragOver)
        $listBox.remove_DragDrop($listBox_DragDrop)
        $listBox.remove_DragDrop($listBox_DragDrop)
        $form.remove_FormClosed($Form_Cleanup_FormClosed)
    }
    catch [Exception]
    { }
}


### Wire up events ###
$button.Add_Click($button_Click)
$listBox.Add_DragOver($listBox_DragOver)
$listBox.Add_DragDrop($listBox_DragDrop)
$form.Add_FormClosed($form_FormClosed)


#### Show form ###
[void] $form.ShowDialog()
