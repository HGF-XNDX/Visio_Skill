param(
    [string] $SpecPath,
    [string] $OutputPath = (Join-Path (Get-Location) 'visio-diagram.vsdx'),
    [switch] $Open,
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
    $displayText = [string] (Get-PropertyValue $Node 'text' (Get-PropertyValue $Node 'id' 'Node'))
    if ($shapeKind -eq 'diamond') {
        $shape.Text = ''
        $label = $Page.DrawRectangle($x - $width / 3, $y - $height / 5, $x + $width / 3, $y + $height / 5)
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
    $shape.Text = [string] (Get-PropertyValue $Label 'text' '')

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

$resolvedOutput = [System.IO.Path]::GetFullPath($OutputPath)
$outputDirectory = Split-Path -Parent $resolvedOutput
if ($outputDirectory -and -not (Test-Path -LiteralPath $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory | Out-Null
}
if ((Test-Path -LiteralPath $resolvedOutput) -and -not $Force) {
    throw "OutputPath already exists: $resolvedOutput. Re-run with -Force only after overwrite is approved."
}

try {
    $visio = [Runtime.InteropServices.Marshal]::GetActiveObject('Visio.Application')
} catch {
    $visio = New-Object -ComObject Visio.Application
}

$visio.Visible = $true
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

foreach ($link in @(Get-PropertyValue $spec 'links' @())) {
    Add-Link $page $link $nodeMap | Out-Null
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

$null = $doc.SaveAs($resolvedOutput)

if ($Open) {
    $visio.ActiveWindow.Page = $page
}

$result = [pscustomobject]@{
    OutputPath = $resolvedOutput
    Document = $doc.Name
    Page = $page.Name
    ShapeCount = $page.Shapes.Count
}

if ($Json) {
    $result | ConvertTo-Json -Compress
} else {
    $result
}
