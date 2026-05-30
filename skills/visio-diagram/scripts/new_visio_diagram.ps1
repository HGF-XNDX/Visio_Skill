param(
    [string] $SpecPath,
    [string] $OutputPath,
    [switch] $Open,
    [switch] $NoOpen,
    [switch] $Save,
    [switch] $Force,
    [switch] $Json
)

$ErrorActionPreference = 'Stop'

function Get-DefaultSpec {
    return [pscustomobject]@{
        title = 'Codex generated Visio diagram'
        page = [pscustomobject]@{
            name = 'Architecture'
            width = 11
            height = 8.5
        }
        nodes = @(
            [pscustomobject]@{ id = 'client'; text = 'Client'; x = 1.8; y = 6.2; fill = 'RGB(227, 242, 253)' },
            [pscustomobject]@{ id = 'gateway'; text = 'Gateway'; x = 4.2; y = 6.2; fill = 'RGB(232, 245, 233)' },
            [pscustomobject]@{ id = 'api'; text = 'API Service'; x = 4.2; y = 4.5; fill = 'RGB(255, 248, 225)' },
            [pscustomobject]@{ id = 'worker'; text = 'Worker'; x = 6.8; y = 4.5; fill = 'RGB(237, 231, 246)' },
            [pscustomobject]@{ id = 'database'; text = 'Database'; x = 9.1; y = 5.6; fill = 'RGB(243, 229, 245)' },
            [pscustomobject]@{ id = 'cache'; text = 'Cache'; x = 1.8; y = 4.5; fill = 'RGB(255, 235, 238)' }
        )
        links = @(
            [pscustomobject]@{ from = 'client'; to = 'gateway'; text = 'HTTPS'; style = 'arrow' },
            [pscustomobject]@{ from = 'gateway'; to = 'api'; text = 'route'; style = 'arrow' },
            [pscustomobject]@{ from = 'api'; to = 'worker'; text = 'queue'; style = 'arrow' },
            [pscustomobject]@{ from = 'worker'; to = 'database'; text = 'write'; style = 'arrow' },
            [pscustomobject]@{ from = 'api'; to = 'cache'; text = 'read'; style = 'arrow' }
        )
        notes = @(
            [pscustomobject]@{ text = 'Editable Visio shapes generated through the Visio COM object model.'; x = 1.0; y = 1.0; width = 9.0; height = 0.75 }
        )
    }
}

function Get-PropertyValue {
    param($Object, [string] $Name, $Default)
    if ($null -eq $Object) { return $Default }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property -or $null -eq $property.Value) { return $Default }
    return $property.Value
}

function New-SubscriptText {
    param([string] $Token)

    $map = @{
        '0' = [string] [char] 0x2080
        '1' = [string] [char] 0x2081
        '2' = [string] [char] 0x2082
        '3' = [string] [char] 0x2083
        '4' = [string] [char] 0x2084
        '5' = [string] [char] 0x2085
        '6' = [string] [char] 0x2086
        '7' = [string] [char] 0x2087
        '8' = [string] [char] 0x2088
        '9' = [string] [char] 0x2089
        'a' = [string] [char] 0x2090
        'e' = [string] [char] 0x2091
        'h' = [string] [char] 0x2095
        'i' = [string] [char] 0x1D62
        'j' = [string] [char] 0x2C7C
        'k' = [string] [char] 0x2096
        'l' = [string] [char] 0x2097
        'm' = [string] [char] 0x2098
        'n' = [string] [char] 0x2099
        'o' = [string] [char] 0x2092
        'p' = [string] [char] 0x209A
        'r' = [string] [char] 0x1D63
        's' = [string] [char] 0x209B
        't' = [string] [char] 0x209C
        'u' = [string] [char] 0x1D64
        'v' = [string] [char] 0x1D65
        'x' = [string] [char] 0x2093
    }

    $parts = @()
    foreach ($char in $Token.ToCharArray()) {
        $key = [string] $char
        if ($map.ContainsKey($key)) {
            $parts += $map[$key]
        } else {
            $parts += $key
        }
    }

    return -join $parts
}

function Format-Text {
    param([string] $Text, $Spec)

    if (-not [bool] (Get-PropertyValue $Spec 'subscripts' $false)) {
        return $Text
    }

    $result = $Text
    foreach ($token in @('train', 'new', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'k', 'v', 'o', 'm', 'n')) {
        $result = $result.Replace("_$token", (New-SubscriptText $token))
    }
    return $result
}

function Get-NormalizedLengths {
    param($Values, [int] $Count, [double] $Total)

    $items = @($Values)
    if ($items.Count -ne $Count) {
        $result = @()
        for ($i = 0; $i -lt $Count; $i += 1) { $result += ($Total / $Count) }
        return $result
    }

    $sum = 0.0
    foreach ($item in $items) { $sum += [double] $item }
    if ($sum -le 0) {
        $result = @()
        for ($i = 0; $i -lt $Count; $i += 1) { $result += ($Total / $Count) }
        return $result
    }

    $normalized = @()
    foreach ($item in $items) { $normalized += ($Total * [double] $item / $sum) }
    return $normalized
}

function Set-ShapeStyle {
    param($Shape, $Spec)

    $fill = [string] (Get-PropertyValue $Spec 'fill' 'RGB(245, 247, 250)')
    $line = [string] (Get-PropertyValue $Spec 'line' 'RGB(58, 89, 128)')
    $lineWeight = [string] (Get-PropertyValue $Spec 'lineWeight' '1.25 pt')
    $fontSize = [string] (Get-PropertyValue $Spec 'fontSize' '10 pt')
    $font = [string] (Get-PropertyValue $Spec 'font' 'Arial')
    $fontColor = [string] (Get-PropertyValue $Spec 'fontColor' 'RGB(0, 0, 0)')
    $linePattern = [string] (Get-PropertyValue $Spec 'linePattern' '1')
    $fillTransparency = [string] (Get-PropertyValue $Spec 'fillTransparency' '')

    if ($fill -eq 'none') {
        $Shape.CellsU('FillPattern').FormulaU = '0'
    } else {
        $Shape.CellsU('FillForegnd').FormulaU = $fill
        if ($fillTransparency.Length -gt 0) {
            $Shape.CellsU('FillForegndTrans').FormulaU = $fillTransparency
        }
    }

    if ($line -eq 'none') {
        $Shape.CellsU('LinePattern').FormulaU = '0'
    } else {
        $Shape.CellsU('LineColor').FormulaU = $line
        $Shape.CellsU('LineWeight').FormulaU = $lineWeight
        $Shape.CellsU('LinePattern').FormulaU = $linePattern
    }

    $Shape.CellsU('Char.Size').FormulaU = $fontSize
    $Shape.CellsU('Char.Font').FormulaU = "FONT(`"$font`")"
    $Shape.CellsU('Char.Color').FormulaU = $fontColor
    $Shape.CellsU('Para.HorzAlign').FormulaU = [string] (Get-PropertyValue $Spec 'hAlign' '1')
    $Shape.CellsU('VerticalAlign').FormulaU = [string] (Get-PropertyValue $Spec 'vAlign' '1')
}

function New-BasicShape {
    param($Page, [double] $X, [double] $Y, [double] $Width, [double] $Height, [string] $ShapeKind)

    if ($ShapeKind -eq 'ellipse' -or $ShapeKind -eq 'circle') {
        return $Page.DrawOval($X - $Width / 2, $Y - $Height / 2, $X + $Width / 2, $Y + $Height / 2)
    }

    $shape = $Page.DrawRectangle($X - $Width / 2, $Y - $Height / 2, $X + $Width / 2, $Y + $Height / 2)
    if ($ShapeKind -eq 'diamond') {
        $shape.CellsU('Angle').FormulaU = '45 deg'
    }
    if ($ShapeKind -eq 'roundRect' -or $ShapeKind -eq 'roundedRectangle' -or $ShapeKind -eq 'rectangle') {
        $shape.CellsU('Rounding').FormulaU = [string] (Get-PropertyValue ([pscustomobject]@{}) 'rounding' '0.08 in')
    }
    return $shape
}

function Add-Node {
    param($Page, $Node)

    $x = [double] (Get-PropertyValue $Node 'x' 1)
    $y = [double] (Get-PropertyValue $Node 'y' 1)
    $width = [double] (Get-PropertyValue $Node 'width' 1.6)
    $height = [double] (Get-PropertyValue $Node 'height' 0.75)
    $shapeKind = [string] (Get-PropertyValue $Node 'shape' 'rectangle')
    $layerCopies = [int] (Get-PropertyValue $Node 'layerCopies' 0)
    $offsetX = [double] (Get-PropertyValue $Node 'copyOffsetX' 0.16)
    $offsetY = [double] (Get-PropertyValue $Node 'copyOffsetY' 0.10)

    for ($i = $layerCopies; $i -ge 1; $i -= 1) {
        $copyShape = New-BasicShape $Page ($x + $i * $offsetX) ($y + $i * $offsetY) $width $height $shapeKind
        $copySpec = [pscustomobject]@{
            fill = [string] (Get-PropertyValue $Node 'copyFill' (Get-PropertyValue $Node 'fill' 'RGB(245, 247, 250)'))
            line = [string] (Get-PropertyValue $Node 'copyLine' 'RGB(190, 190, 190)')
            lineWeight = [string] (Get-PropertyValue $Node 'copyLineWeight' '1 pt')
            fontSize = '1 pt'
            fontColor = 'RGB(255, 255, 255)'
        }
        Set-ShapeStyle $copyShape $copySpec
        $copyShape.Text = ''
    }

    $shape = New-BasicShape $Page $x $y $width $height $shapeKind
    if ($shapeKind -ne 'ellipse' -and $shapeKind -ne 'circle') {
        $shape.CellsU('Rounding').FormulaU = [string] (Get-PropertyValue $Node 'rounding' '0.08 in')
    }
    $angle = [string] (Get-PropertyValue $Node 'angle' '')
    if ($angle.Length -gt 0) {
        $shape.CellsU('Angle').FormulaU = $angle
    }
    $displayText = Format-Text ([string] (Get-PropertyValue $Node 'text' (Get-PropertyValue $Node 'id' 'Node'))) $Node
    if ($shapeKind -eq 'diamond') {
        $shape.Text = ''
        $label = $Page.DrawRectangle($x - $width * 0.36, $y - $height * 0.22, $x + $width * 0.36, $y + $height * 0.22)
        $label.Text = $displayText
        Set-ShapeStyle $label ([pscustomobject]@{
            fill = 'none'
            line = 'none'
            font = [string] (Get-PropertyValue $Node 'font' 'Arial')
            fontSize = [string] (Get-PropertyValue $Node 'fontSize' '10 pt')
            fontColor = [string] (Get-PropertyValue $Node 'fontColor' 'RGB(0, 0, 0)')
        })
    } else {
        $shape.Text = $displayText
    }
    Set-ShapeStyle $shape $Node

    return [pscustomobject]@{
        Id = [string] (Get-PropertyValue $Node 'id' $shape.ID)
        Shape = $shape
        X = $x
        Y = $y
        Width = $width
        Height = $height
    }
}

function Get-EdgePoint {
    param($From, $To)

    $dx = $To.X - $From.X
    $dy = $To.Y - $From.Y

    if ([Math]::Abs($dx) -ge [Math]::Abs($dy)) {
        $sign = if ($dx -ge 0) { 1 } else { -1 }
        return [pscustomobject]@{ X = $From.X + $sign * $From.Width / 2; Y = $From.Y }
    }

    $signY = if ($dy -ge 0) { 1 } else { -1 }
    return [pscustomobject]@{ X = $From.X; Y = $From.Y + $signY * $From.Height / 2 }
}

function Add-Link {
    param($Page, $Link, $NodeMap)

    $fromId = [string] (Get-PropertyValue $Link 'from' '')
    $toId = [string] (Get-PropertyValue $Link 'to' '')

    if (-not $NodeMap.ContainsKey($fromId)) { throw "Unknown link source node id: $fromId" }
    if (-not $NodeMap.ContainsKey($toId)) { throw "Unknown link target node id: $toId" }

    $from = $NodeMap[$fromId]
    $to = $NodeMap[$toId]
    $p1 = Get-EdgePoint $from $to
    $p2 = Get-EdgePoint $to $from

    $line = $Page.DrawLine($p1.X, $p1.Y, $p2.X, $p2.Y)
    $line.CellsU('LineColor').FormulaU = [string] (Get-PropertyValue $Link 'line' 'RGB(80, 80, 80)')
    $line.CellsU('LineWeight').FormulaU = [string] (Get-PropertyValue $Link 'lineWeight' '1.25 pt')
    $line.CellsU('LinePattern').FormulaU = [string] (Get-PropertyValue $Link 'linePattern' '1')

    $style = [string] (Get-PropertyValue $Link 'style' 'arrow')
    if ($style -ne 'line') {
        $line.CellsU('EndArrow').FormulaU = '13'
    }

    $text = [string] (Get-PropertyValue $Link 'text' '')
    if ($text.Length -gt 0) {
        $midX = ($p1.X + $p2.X) / 2
        $midY = ($p1.Y + $p2.Y) / 2
        $labelWidth = [double] (Get-PropertyValue $Link 'labelWidth' 0.5)
        $labelHeight = [double] (Get-PropertyValue $Link 'labelHeight' 0.22)
        $label = $Page.DrawRectangle($midX - $labelWidth / 2, $midY - $labelHeight / 2, $midX + $labelWidth / 2, $midY + $labelHeight / 2)
        $label.Text = $text
        Set-ShapeStyle $label ([pscustomobject]@{
            fill = 'none'
            line = 'none'
            font = [string] (Get-PropertyValue $Link 'font' 'Arial')
            fontSize = [string] (Get-PropertyValue $Link 'fontSize' '8 pt')
            fontColor = [string] (Get-PropertyValue $Link 'fontColor' 'RGB(0, 0, 0)')
        })
    }

    return $line
}

function Add-Arrow {
    param($Page, $Arrow)

    $x1 = [double] (Get-PropertyValue $Arrow 'x1' 0)
    $y1 = [double] (Get-PropertyValue $Arrow 'y1' 0)
    $x2 = [double] (Get-PropertyValue $Arrow 'x2' 1)
    $y2 = [double] (Get-PropertyValue $Arrow 'y2' 1)

    $line = $Page.DrawLine($x1, $y1, $x2, $y2)
    $line.CellsU('LineColor').FormulaU = [string] (Get-PropertyValue $Arrow 'line' 'RGB(0, 0, 0)')
    $line.CellsU('LineWeight').FormulaU = [string] (Get-PropertyValue $Arrow 'lineWeight' '1.5 pt')
    $line.CellsU('LinePattern').FormulaU = [string] (Get-PropertyValue $Arrow 'linePattern' '1')

    $style = [string] (Get-PropertyValue $Arrow 'style' 'arrow')
    if ($style -ne 'line') {
        $line.CellsU('EndArrow').FormulaU = [string] (Get-PropertyValue $Arrow 'endArrow' '13')
    }
    if ([bool] (Get-PropertyValue $Arrow 'beginArrow' $false)) {
        $line.CellsU('BeginArrow').FormulaU = '13'
    }

    $text = [string] (Get-PropertyValue $Arrow 'text' '')
    if ($text.Length -gt 0) {
        $midX = ($x1 + $x2) / 2
        $midY = ($y1 + $y2) / 2
        $labelWidth = [double] (Get-PropertyValue $Arrow 'labelWidth' 0.5)
        $labelHeight = [double] (Get-PropertyValue $Arrow 'labelHeight' 0.22)
        $label = $Page.DrawRectangle($midX - $labelWidth / 2, $midY - $labelHeight / 2, $midX + $labelWidth / 2, $midY + $labelHeight / 2)
        $label.Text = $text
        Set-ShapeStyle $label ([pscustomobject]@{
            fill = 'none'
            line = 'none'
            font = [string] (Get-PropertyValue $Arrow 'font' 'Arial')
            fontSize = [string] (Get-PropertyValue $Arrow 'fontSize' '8 pt')
            fontColor = [string] (Get-PropertyValue $Arrow 'fontColor' 'RGB(0, 0, 0)')
        })
    }

    return $line
}

function Add-Label {
    param($Page, $Label)

    $x = [double] (Get-PropertyValue $Label 'x' 1)
    $y = [double] (Get-PropertyValue $Label 'y' 1)
    $width = [double] (Get-PropertyValue $Label 'width' 1.5)
    $height = [double] (Get-PropertyValue $Label 'height' 0.35)
    $shape = $Page.DrawRectangle($x - $width / 2, $y - $height / 2, $x + $width / 2, $y + $height / 2)
    $shape.Text = Format-Text ([string] (Get-PropertyValue $Label 'text' '')) $Label

    $labelSpec = [pscustomobject]@{
        fill = [string] (Get-PropertyValue $Label 'fill' 'none')
        line = [string] (Get-PropertyValue $Label 'line' 'none')
        font = [string] (Get-PropertyValue $Label 'font' 'Arial')
        fontSize = [string] (Get-PropertyValue $Label 'fontSize' '12 pt')
        fontColor = [string] (Get-PropertyValue $Label 'fontColor' 'RGB(0, 0, 0)')
        hAlign = [string] (Get-PropertyValue $Label 'hAlign' '1')
        vAlign = [string] (Get-PropertyValue $Label 'vAlign' '1')
    }
    Set-ShapeStyle $shape $labelSpec
    return $shape
}

function Add-Table {
    param($Page, $Table)

    $x = [double] (Get-PropertyValue $Table 'x' 1)
    $y = [double] (Get-PropertyValue $Table 'y' 1)
    $width = [double] (Get-PropertyValue $Table 'width' 2)
    $height = [double] (Get-PropertyValue $Table 'height' 1)
    $rows = @(Get-PropertyValue $Table 'rows' @())
    if ($rows.Count -eq 0) { return }

    $rowCount = $rows.Count
    $colCount = 0
    foreach ($row in $rows) {
        $colCount = [Math]::Max($colCount, @($row).Count)
    }
    if ($colCount -eq 0) { return }

    $colWidths = Get-NormalizedLengths (Get-PropertyValue $Table 'colWidths' @()) $colCount $width
    $rowHeights = Get-NormalizedLengths (Get-PropertyValue $Table 'rowHeights' @()) $rowCount $height
    $left = $x - $width / 2
    $top = $y + $height / 2
    $headerRows = [int] (Get-PropertyValue $Table 'headerRows' 0)
    $fill = [string] (Get-PropertyValue $Table 'fill' 'RGB(255,255,255)')
    $headerFill = [string] (Get-PropertyValue $Table 'headerFill' 'RGB(245,247,250)')
    $line = [string] (Get-PropertyValue $Table 'line' 'RGB(140,140,140)')
    $fontSize = [string] (Get-PropertyValue $Table 'fontSize' '9 pt')
    $font = [string] (Get-PropertyValue $Table 'font' 'Arial')

    $covered = @{}
    for ($r = 0; $r -lt $rowCount; $r += 1) {
        $row = @($rows[$r])
        $rowTop = $top
        for ($ri = 0; $ri -lt $r; $ri += 1) { $rowTop -= $rowHeights[$ri] }
        for ($c = 0; $c -lt $colCount; $c += 1) {
            $key = "$r,$c"
            if ($covered.ContainsKey($key)) { continue }

            $cellValue = if ($c -lt $row.Count) { $row[$c] } else { '' }
            $cellText = [string] $cellValue
            $cellFill = if ($r -lt $headerRows) { $headerFill } else { $fill }
            $cellLine = $line
            $cellFont = $font
            $cellFontSize = $fontSize
            $cellFontColor = [string] (Get-PropertyValue $Table 'fontColor' 'RGB(0,0,0)')
            $colSpan = 1
            $rowSpan = 1
            if ($null -ne $cellValue -and $null -ne $cellValue.PSObject.Properties['text']) {
                $cellText = Format-Text ([string] (Get-PropertyValue $cellValue 'text' '')) $cellValue
                $cellFill = [string] (Get-PropertyValue $cellValue 'fill' $cellFill)
                $cellLine = [string] (Get-PropertyValue $cellValue 'line' $cellLine)
                $cellFont = [string] (Get-PropertyValue $cellValue 'font' $cellFont)
                $cellFontSize = [string] (Get-PropertyValue $cellValue 'fontSize' $cellFontSize)
                $cellFontColor = [string] (Get-PropertyValue $cellValue 'fontColor' $cellFontColor)
                $colSpan = [int] (Get-PropertyValue $cellValue 'colSpan' 1)
                $rowSpan = [int] (Get-PropertyValue $cellValue 'rowSpan' 1)
            } else {
                $cellText = Format-Text $cellText $Table
            }

            if ($colSpan -lt 1) { $colSpan = 1 }
            if ($rowSpan -lt 1) { $rowSpan = 1 }
            if ($c + $colSpan -gt $colCount) { $colSpan = $colCount - $c }
            if ($r + $rowSpan -gt $rowCount) { $rowSpan = $rowCount - $r }

            $cellLeft = $left
            for ($ci = 0; $ci -lt $c; $ci += 1) { $cellLeft += $colWidths[$ci] }
            $cellWidth = 0.0
            for ($ci = $c; $ci -lt $c + $colSpan; $ci += 1) { $cellWidth += $colWidths[$ci] }
            $cellHeight = 0.0
            for ($ri = $r; $ri -lt $r + $rowSpan; $ri += 1) { $cellHeight += $rowHeights[$ri] }

            for ($rs = $r; $rs -lt $r + $rowSpan; $rs += 1) {
                for ($cs = $c; $cs -lt $c + $colSpan; $cs += 1) {
                    if ($rs -ne $r -or $cs -ne $c) { $covered["$rs,$cs"] = $true }
                }
            }
            $cellTop = $rowTop
            $shape = $Page.DrawRectangle($cellLeft, $cellTop - $cellHeight, $cellLeft + $cellWidth, $cellTop)
            $shape.Text = $cellText
            Set-ShapeStyle $shape ([pscustomobject]@{
                fill = $cellFill
                line = $cellLine
                lineWeight = [string] (Get-PropertyValue $Table 'lineWeight' '0.75 pt')
                font = $cellFont
                fontSize = $cellFontSize
                fontColor = $cellFontColor
            })
        }
    }
}

function Add-Cylinder {
    param($Page, $Cylinder)

    $x = [double] (Get-PropertyValue $Cylinder 'x' 1)
    $y = [double] (Get-PropertyValue $Cylinder 'y' 1)
    $width = [double] (Get-PropertyValue $Cylinder 'width' 1.2)
    $height = [double] (Get-PropertyValue $Cylinder 'height' 0.8)
    $ellipseHeight = [double] (Get-PropertyValue $Cylinder 'ellipseHeight' 0.18)
    $left = $x - $width / 2
    $right = $x + $width / 2
    $bottom = $y - $height / 2
    $top = $y + $height / 2

    $body = $Page.DrawRectangle($left, $bottom, $right, $top)
    $body.Text = Format-Text ([string] (Get-PropertyValue $Cylinder 'text' '')) $Cylinder
    Set-ShapeStyle $body ([pscustomobject]@{
        fill = [string] (Get-PropertyValue $Cylinder 'fill' 'RGB(255,255,255)')
        line = [string] (Get-PropertyValue $Cylinder 'line' 'RGB(120,120,120)')
        lineWeight = [string] (Get-PropertyValue $Cylinder 'lineWeight' '1 pt')
        font = [string] (Get-PropertyValue $Cylinder 'font' 'Arial')
        fontSize = [string] (Get-PropertyValue $Cylinder 'fontSize' '10 pt')
    })

    $topOval = $Page.DrawOval($left, $top - $ellipseHeight, $right, $top + $ellipseHeight)
    Set-ShapeStyle $topOval ([pscustomobject]@{
        fill = [string] (Get-PropertyValue $Cylinder 'fill' 'RGB(255,255,255)')
        line = [string] (Get-PropertyValue $Cylinder 'line' 'RGB(120,120,120)')
        lineWeight = [string] (Get-PropertyValue $Cylinder 'lineWeight' '1 pt')
        fontSize = '1 pt'
    })
    $topOval.Text = ''

    $bottomOval = $Page.DrawOval($left, $bottom - $ellipseHeight, $right, $bottom + $ellipseHeight)
    Set-ShapeStyle $bottomOval ([pscustomobject]@{
        fill = 'none'
        line = [string] (Get-PropertyValue $Cylinder 'line' 'RGB(120,120,120)')
        lineWeight = [string] (Get-PropertyValue $Cylinder 'lineWeight' '1 pt')
        fontSize = '1 pt'
    })
    $bottomOval.Text = ''
}

function Add-Panel {
    param($Page, $Panel)

    $x = [double] (Get-PropertyValue $Panel 'x' 1)
    $y = [double] (Get-PropertyValue $Panel 'y' 1)
    $width = [double] (Get-PropertyValue $Panel 'width' 2)
    $height = [double] (Get-PropertyValue $Panel 'height' 1)
    $title = [string] (Get-PropertyValue $Panel 'title' '')
    $headerHeight = [double] (Get-PropertyValue $Panel 'headerHeight' 0.28)

    $outer = $Page.DrawRectangle($x - $width / 2, $y - $height / 2, $x + $width / 2, $y + $height / 2)
    $outer.Text = ''
    Set-ShapeStyle $outer ([pscustomobject]@{
        fill = [string] (Get-PropertyValue $Panel 'fill' 'RGB(255,255,255)')
        line = [string] (Get-PropertyValue $Panel 'line' 'RGB(140,140,140)')
        lineWeight = [string] (Get-PropertyValue $Panel 'lineWeight' '1 pt')
    })

    if ($title.Length -gt 0) {
        $header = $Page.DrawRectangle($x - $width / 2, $y + $height / 2 - $headerHeight, $x + $width / 2, $y + $height / 2)
        $header.Text = Format-Text $title $Panel
        Set-ShapeStyle $header ([pscustomobject]@{
            fill = [string] (Get-PropertyValue $Panel 'headerFill' 'RGB(245,247,250)')
            line = [string] (Get-PropertyValue $Panel 'line' 'RGB(140,140,140)')
            lineWeight = [string] (Get-PropertyValue $Panel 'lineWeight' '1 pt')
            font = [string] (Get-PropertyValue $Panel 'font' 'Arial')
            fontSize = [string] (Get-PropertyValue $Panel 'fontSize' '10 pt')
        })
    }
}

function Add-List {
    param($Page, $List)

    $x = [double] (Get-PropertyValue $List 'x' 1)
    $y = [double] (Get-PropertyValue $List 'y' 1)
    $width = [double] (Get-PropertyValue $List 'width' 2)
    $height = [double] (Get-PropertyValue $List 'height' 1)
    $items = @(Get-PropertyValue $List 'items' @())
    $ordered = [bool] (Get-PropertyValue $List 'ordered' $false)
    $drawBox = [bool] (Get-PropertyValue $List 'box' $false)

    if ($drawBox) {
        $box = $Page.DrawRectangle($x - $width / 2, $y - $height / 2, $x + $width / 2, $y + $height / 2)
        $box.Text = ''
        Set-ShapeStyle $box $List
    }

    if ($items.Count -eq 0) { return }
    $lineHeight = $height / [Math]::Max($items.Count, 1)
    $top = $y + $height / 2
    for ($i = 0; $i -lt $items.Count; $i += 1) {
        $raw = $items[$i]
        $text = if ($null -ne $raw.PSObject.Properties['text']) { [string] (Get-PropertyValue $raw 'text' '') } else { [string] $raw }
        $prefix = if ($ordered) { "$($i + 1). " } else { [string] (Get-PropertyValue $List 'bullet' '- ') }
        if (-not $ordered -and $null -eq $List.PSObject.Properties['bullet']) {
            $prefix = '- '
        }
        $label = $Page.DrawRectangle($x - $width / 2 + 0.05, $top - ($i + 1) * $lineHeight, $x + $width / 2 - 0.05, $top - $i * $lineHeight)
        $label.Text = $prefix + (Format-Text $text $List)
        Set-ShapeStyle $label ([pscustomobject]@{
            fill = 'none'
            line = 'none'
            font = [string] (Get-PropertyValue $List 'font' 'Arial')
            fontSize = [string] (Get-PropertyValue $List 'fontSize' '9 pt')
            fontColor = [string] (Get-PropertyValue $List 'fontColor' 'RGB(0,0,0)')
            hAlign = '0'
        })
    }
}

function Add-Tree {
    param($Page, $Tree)

    $nodes = @(Get-PropertyValue $Tree 'nodes' @())
    $edges = @(Get-PropertyValue $Tree 'edges' @())
    $treeNodeMap = @{}

    foreach ($node in $nodes) {
        $created = Add-Node $Page ([pscustomobject]@{
            id = [string] (Get-PropertyValue $node 'id' '')
            text = [string] (Get-PropertyValue $node 'text' '')
            shape = [string] (Get-PropertyValue $node 'shape' 'circle')
            x = [double] (Get-PropertyValue $node 'x' 1)
            y = [double] (Get-PropertyValue $node 'y' 1)
            width = [double] (Get-PropertyValue $node 'width' 0.42)
            height = [double] (Get-PropertyValue $node 'height' 0.42)
            fill = [string] (Get-PropertyValue $node 'fill' 'RGB(255,255,255)')
            line = [string] (Get-PropertyValue $node 'line' 'RGB(100,100,100)')
            fontSize = [string] (Get-PropertyValue $node 'fontSize' '8 pt')
        })
        if ($created.Id.Length -gt 0) {
            $treeNodeMap[$created.Id] = $created
        }
    }

    foreach ($edge in $edges) {
        Add-Link $Page $edge $treeNodeMap | Out-Null
    }
}

function Add-BarChart {
    param($Page, $Chart)

    $x = [double] (Get-PropertyValue $Chart 'x' 1)
    $y = [double] (Get-PropertyValue $Chart 'y' 1)
    $width = [double] (Get-PropertyValue $Chart 'width' 2)
    $height = [double] (Get-PropertyValue $Chart 'height' 1)
    $bars = @(Get-PropertyValue $Chart 'bars' @())
    if ($bars.Count -eq 0) { return }

    $panel = $Page.DrawRectangle($x - $width / 2, $y - $height / 2, $x + $width / 2, $y + $height / 2)
    $panel.Text = [string] (Get-PropertyValue $Chart 'title' '')
    Set-ShapeStyle $panel ([pscustomobject]@{
        fill = [string] (Get-PropertyValue $Chart 'fill' 'RGB(255,255,255)')
        line = [string] (Get-PropertyValue $Chart 'line' 'RGB(180,180,180)')
        fontSize = [string] (Get-PropertyValue $Chart 'titleFontSize' '8 pt')
        vAlign = '0'
    })

    $maxValue = [double] (Get-PropertyValue $Chart 'maxValue' 0)
    if ($maxValue -le 0) {
        foreach ($bar in $bars) {
            $maxValue = [Math]::Max($maxValue, [double] (Get-PropertyValue $bar 'value' 0))
        }
    }
    if ($maxValue -le 0) { $maxValue = 1 }

    $plotLeft = $x - $width / 2 + 0.25
    $plotBottom = $y - $height / 2 + 0.28
    $plotWidth = $width - 0.45
    $plotHeight = $height - 0.62
    $gap = $plotWidth / ($bars.Count * 2 + 1)
    $barWidth = $gap

    Add-Arrow $Page ([pscustomobject]@{ x1 = $plotLeft; y1 = $plotBottom; x2 = $plotLeft + $plotWidth; y2 = $plotBottom; style = 'line'; lineWeight = '0.7 pt' }) | Out-Null
    Add-Arrow $Page ([pscustomobject]@{ x1 = $plotLeft; y1 = $plotBottom; x2 = $plotLeft; y2 = $plotBottom + $plotHeight; style = 'line'; lineWeight = '0.7 pt' }) | Out-Null

    for ($i = 0; $i -lt $bars.Count; $i += 1) {
        $bar = $bars[$i]
        $value = [double] (Get-PropertyValue $bar 'value' 0)
        $barHeight = $plotHeight * $value / $maxValue
        $barLeft = $plotLeft + $gap + $i * 2 * $gap
        $barShape = $Page.DrawRectangle($barLeft, $plotBottom, $barLeft + $barWidth, $plotBottom + $barHeight)
        $barShape.Text = ''
        Set-ShapeStyle $barShape ([pscustomobject]@{
            fill = [string] (Get-PropertyValue $bar 'fill' 'RGB(220,230,245)')
            line = [string] (Get-PropertyValue $bar 'line' 'RGB(120,120,120)')
            fontSize = '1 pt'
        })
        Add-Label $Page ([pscustomobject]@{
            text = [string] (Get-PropertyValue $bar 'text' $value)
            x = $barLeft + $barWidth / 2
            y = $plotBottom + $barHeight + 0.08
            width = 0.42
            height = 0.15
            fontSize = [string] (Get-PropertyValue $Chart 'valueFontSize' '5 pt')
        }) | Out-Null
        Add-Label $Page ([pscustomobject]@{
            text = [string] (Get-PropertyValue $bar 'label' '')
            x = $barLeft + $barWidth / 2
            y = $plotBottom - 0.12
            width = 0.48
            height = 0.16
            fontSize = [string] (Get-PropertyValue $Chart 'labelFontSize' '5 pt')
        }) | Out-Null
    }
}

function Add-LineChart {
    param($Page, $Chart)

    $x = [double] (Get-PropertyValue $Chart 'x' 1)
    $y = [double] (Get-PropertyValue $Chart 'y' 1)
    $width = [double] (Get-PropertyValue $Chart 'width' 2)
    $height = [double] (Get-PropertyValue $Chart 'height' 1)
    $series = @(Get-PropertyValue $Chart 'series' @())
    if ($series.Count -eq 0) { return }

    $panel = $Page.DrawRectangle($x - $width / 2, $y - $height / 2, $x + $width / 2, $y + $height / 2)
    $panel.Text = [string] (Get-PropertyValue $Chart 'title' '')
    Set-ShapeStyle $panel ([pscustomobject]@{
        fill = [string] (Get-PropertyValue $Chart 'fill' 'RGB(255,255,255)')
        line = [string] (Get-PropertyValue $Chart 'line' 'RGB(180,180,180)')
        fontSize = [string] (Get-PropertyValue $Chart 'titleFontSize' '8 pt')
        vAlign = '0'
    })

    $allValues = @()
    $maxPoints = 0
    foreach ($s in $series) {
        $values = @(Get-PropertyValue $s 'values' @())
        $maxPoints = [Math]::Max($maxPoints, $values.Count)
        foreach ($value in $values) { $allValues += [double] $value }
    }
    if ($maxPoints -lt 2) { return }

    $minValue = [double] (Get-PropertyValue $Chart 'minValue' ($allValues | Measure-Object -Minimum).Minimum)
    $maxValue = [double] (Get-PropertyValue $Chart 'maxValue' ($allValues | Measure-Object -Maximum).Maximum)
    if ($maxValue -le $minValue) { $maxValue = $minValue + 1 }

    $plotLeft = $x - $width / 2 + 0.32
    $plotBottom = $y - $height / 2 + 0.3
    $plotWidth = $width - 0.55
    $plotHeight = $height - 0.68
    Add-Arrow $Page ([pscustomobject]@{ x1 = $plotLeft; y1 = $plotBottom; x2 = $plotLeft + $plotWidth; y2 = $plotBottom; style = 'line'; lineWeight = '0.7 pt' }) | Out-Null
    Add-Arrow $Page ([pscustomobject]@{ x1 = $plotLeft; y1 = $plotBottom; x2 = $plotLeft; y2 = $plotBottom + $plotHeight; style = 'line'; lineWeight = '0.7 pt' }) | Out-Null

    foreach ($s in $series) {
        $values = @(Get-PropertyValue $s 'values' @())
        $color = [string] (Get-PropertyValue $s 'line' 'RGB(80,120,180)')
        $prev = $null
        for ($i = 0; $i -lt $values.Count; $i += 1) {
            $px = $plotLeft + $plotWidth * $i / [Math]::Max($values.Count - 1, 1)
            $py = $plotBottom + $plotHeight * (([double] $values[$i] - $minValue) / ($maxValue - $minValue))
            if ($null -ne $prev) {
                Add-Arrow $Page ([pscustomobject]@{ x1 = $prev.X; y1 = $prev.Y; x2 = $px; y2 = $py; style = 'line'; line = $color; lineWeight = [string] (Get-PropertyValue $s 'lineWeight' '1.2 pt') }) | Out-Null
            }
            if ([bool] (Get-PropertyValue $s 'markers' $true)) {
                $marker = $Page.DrawOval($px - 0.035, $py - 0.035, $px + 0.035, $py + 0.035)
                $marker.Text = ''
                Set-ShapeStyle $marker ([pscustomobject]@{ fill = $color; line = $color; fontSize = '1 pt' })
            }
            $prev = [pscustomobject]@{ X = $px; Y = $py }
        }
    }
}

function Add-ElbowConnector {
    param($Page, $Connector)

    $points = @(Get-PropertyValue $Connector 'points' @())
    if ($points.Count -lt 2) { return }

    for ($i = 0; $i -lt $points.Count - 1; $i += 1) {
        $p1 = $points[$i]
        $p2 = $points[$i + 1]
        $segment = [pscustomobject]@{
            x1 = [double] (Get-PropertyValue $p1 'x' 0)
            y1 = [double] (Get-PropertyValue $p1 'y' 0)
            x2 = [double] (Get-PropertyValue $p2 'x' 0)
            y2 = [double] (Get-PropertyValue $p2 'y' 0)
            style = if ($i -eq $points.Count - 2) { [string] (Get-PropertyValue $Connector 'style' 'arrow') } else { 'line' }
            line = [string] (Get-PropertyValue $Connector 'line' 'RGB(0,0,0)')
            lineWeight = [string] (Get-PropertyValue $Connector 'lineWeight' '1.25 pt')
            linePattern = [string] (Get-PropertyValue $Connector 'linePattern' '1')
        }
        Add-Arrow $Page $segment | Out-Null
    }
}

function Add-CurvedConnector {
    param($Page, $Connector)

    $points = @(Get-PropertyValue $Connector 'points' @())
    if ($points.Count -lt 3) { return }
    $segments = [int] (Get-PropertyValue $Connector 'segments' 18)
    if ($segments -lt 4) { $segments = 4 }

    $sampled = @()
    for ($i = 0; $i -le $segments; $i += 1) {
        $t = $i / $segments
        if ($points.Count -eq 3) {
            $p0 = $points[0]; $p1 = $points[1]; $p2 = $points[2]
            $x = [Math]::Pow(1 - $t, 2) * [double] (Get-PropertyValue $p0 'x' 0) + 2 * (1 - $t) * $t * [double] (Get-PropertyValue $p1 'x' 0) + [Math]::Pow($t, 2) * [double] (Get-PropertyValue $p2 'x' 0)
            $y = [Math]::Pow(1 - $t, 2) * [double] (Get-PropertyValue $p0 'y' 0) + 2 * (1 - $t) * $t * [double] (Get-PropertyValue $p1 'y' 0) + [Math]::Pow($t, 2) * [double] (Get-PropertyValue $p2 'y' 0)
        } else {
            $p0 = $points[0]; $p1 = $points[1]; $p2 = $points[2]; $p3 = $points[3]
            $x = [Math]::Pow(1 - $t, 3) * [double] (Get-PropertyValue $p0 'x' 0) + 3 * [Math]::Pow(1 - $t, 2) * $t * [double] (Get-PropertyValue $p1 'x' 0) + 3 * (1 - $t) * [Math]::Pow($t, 2) * [double] (Get-PropertyValue $p2 'x' 0) + [Math]::Pow($t, 3) * [double] (Get-PropertyValue $p3 'x' 0)
            $y = [Math]::Pow(1 - $t, 3) * [double] (Get-PropertyValue $p0 'y' 0) + 3 * [Math]::Pow(1 - $t, 2) * $t * [double] (Get-PropertyValue $p1 'y' 0) + 3 * (1 - $t) * [Math]::Pow($t, 2) * [double] (Get-PropertyValue $p2 'y' 0) + [Math]::Pow($t, 3) * [double] (Get-PropertyValue $p3 'y' 0)
        }
        $sampled += [pscustomobject]@{ X = $x; Y = $y }
    }

    for ($i = 0; $i -lt $sampled.Count - 1; $i += 1) {
        Add-Arrow $Page ([pscustomobject]@{
            x1 = $sampled[$i].X
            y1 = $sampled[$i].Y
            x2 = $sampled[$i + 1].X
            y2 = $sampled[$i + 1].Y
            style = if ($i -eq $sampled.Count - 2) { [string] (Get-PropertyValue $Connector 'style' 'arrow') } else { 'line' }
            line = [string] (Get-PropertyValue $Connector 'line' 'RGB(0,0,0)')
            lineWeight = [string] (Get-PropertyValue $Connector 'lineWeight' '1.25 pt')
            linePattern = [string] (Get-PropertyValue $Connector 'linePattern' '1')
        }) | Out-Null
    }
}

function Add-Icon {
    param($Page, $Icon)

    $kind = [string] (Get-PropertyValue $Icon 'kind' 'document')
    $x = [double] (Get-PropertyValue $Icon 'x' 1)
    $y = [double] (Get-PropertyValue $Icon 'y' 1)
    $width = [double] (Get-PropertyValue $Icon 'width' 0.5)
    $height = [double] (Get-PropertyValue $Icon 'height' 0.5)
    $fill = [string] (Get-PropertyValue $Icon 'fill' 'RGB(230,235,240)')
    $line = [string] (Get-PropertyValue $Icon 'line' 'RGB(90,90,90)')

    if ($kind -eq 'database' -or $kind -eq 'dataset') {
        Add-Cylinder $Page ([pscustomobject]@{ text = [string] (Get-PropertyValue $Icon 'text' ''); x = $x; y = $y; width = $width; height = $height; fill = $fill; line = $line; fontSize = [string] (Get-PropertyValue $Icon 'fontSize' '8 pt') })
        return
    }

    if ($kind -eq 'document') {
        $doc = $Page.DrawRectangle($x - $width / 2, $y - $height / 2, $x + $width / 2, $y + $height / 2)
        $iconText = [string] (Get-PropertyValue $Icon 'text' '')
        $doc.Text = $iconText
        Set-ShapeStyle $doc ([pscustomobject]@{ fill = $fill; line = $line; fontSize = [string] (Get-PropertyValue $Icon 'fontSize' '7 pt') })
        if ([string]::IsNullOrWhiteSpace($iconText)) {
            Add-Arrow $Page ([pscustomobject]@{ x1 = $x - $width * 0.28; y1 = $y + $height * 0.12; x2 = $x + $width * 0.22; y2 = $y + $height * 0.12; style = 'line'; line = $line; lineWeight = '0.6 pt' }) | Out-Null
            Add-Arrow $Page ([pscustomobject]@{ x1 = $x - $width * 0.28; y1 = $y; x2 = $x + $width * 0.22; y2 = $y; style = 'line'; line = $line; lineWeight = '0.6 pt' }) | Out-Null
        }
        return
    }

    if ($kind -eq 'funnel') {
        $shape = $Page.DrawRectangle($x - $width / 2, $y - $height / 2, $x + $width / 2, $y + $height / 2)
        $shape.Text = [string] (Get-PropertyValue $Icon 'text' 'Filter')
        Set-ShapeStyle $shape ([pscustomobject]@{ fill = $fill; line = $line; fontSize = [string] (Get-PropertyValue $Icon 'fontSize' '9 pt') })
        return
    }

    if ($kind -eq 'chip') {
        $shape = $Page.DrawRectangle($x - $width / 2, $y - $height / 2, $x + $width / 2, $y + $height / 2)
        $shape.Text = [string] (Get-PropertyValue $Icon 'text' 'CPU')
        Set-ShapeStyle $shape ([pscustomobject]@{ fill = $fill; line = $line; fontSize = [string] (Get-PropertyValue $Icon 'fontSize' '9 pt') })
        for ($i = -2; $i -le 2; $i += 1) {
            Add-Arrow $Page ([pscustomobject]@{ x1 = $x - $width / 2 - 0.06; y1 = $y + $i * $height / 6; x2 = $x - $width / 2; y2 = $y + $i * $height / 6; style = 'line'; line = $line; lineWeight = '0.6 pt' }) | Out-Null
            Add-Arrow $Page ([pscustomobject]@{ x1 = $x + $width / 2; y1 = $y + $i * $height / 6; x2 = $x + $width / 2 + 0.06; y2 = $y + $i * $height / 6; style = 'line'; line = $line; lineWeight = '0.6 pt' }) | Out-Null
        }
    }
}

function Add-Title {
    param($Page, [string] $Title, [double] $PageWidth, [double] $PageHeight)

    if ([string]::IsNullOrWhiteSpace($Title)) { return }

    $shape = $Page.DrawRectangle(0.75, $PageHeight - 0.85, $PageWidth - 0.75, $PageHeight - 0.25)
    $shape.Text = $Title
    $shape.CellsU('FillPattern').FormulaU = '0'
    $shape.CellsU('LinePattern').FormulaU = '0'
    $shape.CellsU('Char.Size').FormulaU = '18 pt'
    $shape.CellsU('Char.Font').FormulaU = 'FONT("Arial")'
    $shape.CellsU('Para.HorzAlign').FormulaU = '1'
}

function Add-Note {
    param($Page, $Note)

    $x = [double] (Get-PropertyValue $Note 'x' 1)
    $y = [double] (Get-PropertyValue $Note 'y' 1)
    $width = [double] (Get-PropertyValue $Note 'width' 9)
    $height = [double] (Get-PropertyValue $Note 'height' 0.75)

    $shape = $Page.DrawRectangle($x, $y, $x + $width, $y + $height)
    $shape.Text = [string] (Get-PropertyValue $Note 'text' '')
    Set-ShapeStyle $shape ([pscustomobject]@{
        fill = [string] (Get-PropertyValue $Note 'fill' 'RGB(245, 247, 250)')
        line = [string] (Get-PropertyValue $Note 'line' 'RGB(190, 190, 190)')
        fontSize = [string] (Get-PropertyValue $Note 'fontSize' '9 pt')
        font = [string] (Get-PropertyValue $Note 'font' 'Arial')
    })
}

if ($SpecPath) {
    if (-not (Test-Path -LiteralPath $SpecPath)) {
        throw "SpecPath does not exist: $SpecPath"
    }
    $spec = Get-Content -Raw -Encoding UTF8 -LiteralPath $SpecPath | ConvertFrom-Json
} else {
    $spec = Get-DefaultSpec
}

$keepOpen = [bool] $Open -or -not [bool] $NoOpen
$hasOutputPath = -not [string]::IsNullOrWhiteSpace($OutputPath)
$shouldSave = [bool] $Save -or [bool] $NoOpen -or $hasOutputPath
$resolvedOutput = $null

if ($shouldSave) {
    if (-not $hasOutputPath) {
        $OutputPath = Join-Path (Get-Location) 'visio-diagram.vsdx'
    }

    $resolvedOutput = [System.IO.Path]::GetFullPath($OutputPath)
    $outputDirectory = Split-Path -Parent $resolvedOutput
    if ($outputDirectory -and -not (Test-Path -LiteralPath $outputDirectory)) {
        New-Item -ItemType Directory -Path $outputDirectory | Out-Null
    }
    if ((Test-Path -LiteralPath $resolvedOutput) -and -not $Force) {
        throw "OutputPath already exists: $resolvedOutput. Re-run with -Force only after overwrite is approved."
    }
}

try {
    $visio = [Runtime.InteropServices.Marshal]::GetActiveObject('Visio.Application')
    $createdVisio = $false
} catch {
    $visio = New-Object -ComObject Visio.Application
    $createdVisio = $true
}

$visio.Visible = $keepOpen
$doc = $visio.Documents.Add('')
$page = $visio.ActivePage

$pageSpec = Get-PropertyValue $spec 'page' $null
$pageWidth = [double] (Get-PropertyValue $pageSpec 'width' 11)
$pageHeight = [double] (Get-PropertyValue $pageSpec 'height' 8.5)
$pageName = [string] (Get-PropertyValue $pageSpec 'name' 'Diagram')

$page.Name = $pageName
$page.PageSheet.CellsU('PageWidth').FormulaU = "$pageWidth in"
$page.PageSheet.CellsU('PageHeight').FormulaU = "$pageHeight in"

Add-Title $page ([string] (Get-PropertyValue $spec 'title' '')) $pageWidth $pageHeight

$nodeMap = @{}
foreach ($node in @(Get-PropertyValue $spec 'nodes' @())) {
    $created = Add-Node $page $node
    if ($nodeMap.ContainsKey($created.Id)) {
        throw "Duplicate node id: $($created.Id)"
    }
    $nodeMap[$created.Id] = $created
}

foreach ($panel in @(Get-PropertyValue $spec 'panels' @())) {
    Add-Panel $page $panel
}

foreach ($table in @(Get-PropertyValue $spec 'tables' @())) {
    Add-Table $page $table
}

foreach ($cylinder in @(Get-PropertyValue $spec 'cylinders' @())) {
    Add-Cylinder $page $cylinder
}

foreach ($icon in @(Get-PropertyValue $spec 'icons' @())) {
    Add-Icon $page $icon
}

foreach ($list in @(Get-PropertyValue $spec 'lists' @())) {
    Add-List $page $list
}

foreach ($tree in @(Get-PropertyValue $spec 'trees' @())) {
    Add-Tree $page $tree
}

foreach ($chart in @(Get-PropertyValue $spec 'barCharts' @())) {
    Add-BarChart $page $chart
}

foreach ($chart in @(Get-PropertyValue $spec 'lineCharts' @())) {
    Add-LineChart $page $chart
}

foreach ($link in @(Get-PropertyValue $spec 'links' @())) {
    Add-Link $page $link $nodeMap | Out-Null
}

foreach ($connector in @(Get-PropertyValue $spec 'elbowConnectors' @())) {
    Add-ElbowConnector $page $connector
}

foreach ($connector in @(Get-PropertyValue $spec 'curvedConnectors' @())) {
    Add-CurvedConnector $page $connector
}

foreach ($arrow in @(Get-PropertyValue $spec 'arrows' @())) {
    Add-Arrow $page $arrow | Out-Null
}

foreach ($label in @(Get-PropertyValue $spec 'labels' @())) {
    Add-Label $page $label | Out-Null
}

foreach ($note in @(Get-PropertyValue $spec 'notes' @())) {
    Add-Note $page $note
}

if ($shouldSave) {
    $null = $doc.SaveAs($resolvedOutput)
}

if ($keepOpen) {
    $visio.ActiveWindow.Page = $page
}

$result = [pscustomobject]@{
    OutputPath = $resolvedOutput
    Saved = $shouldSave
    Document = $doc.Name
    Page = $page.Name
    ShapeCount = $page.Shapes.Count
}

if (-not $keepOpen) {
    $doc.Close()
    if ($createdVisio) {
        $visio.Quit()
    }
}

if ($Json) {
    $result | ConvertTo-Json -Compress
} else {
    $result
}
