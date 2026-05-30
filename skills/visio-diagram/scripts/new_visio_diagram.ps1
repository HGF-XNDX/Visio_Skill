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

function Add-Node {
    param($Page, $Node)

    $x = [double] (Get-PropertyValue $Node 'x' 1)
    $y = [double] (Get-PropertyValue $Node 'y' 1)
    $width = [double] (Get-PropertyValue $Node 'width' 1.6)
    $height = [double] (Get-PropertyValue $Node 'height' 0.75)
    $shapeKind = [string] (Get-PropertyValue $Node 'shape' 'rectangle')

    if ($shapeKind -eq 'ellipse') {
        $shape = $Page.DrawOval($x - $width / 2, $y - $height / 2, $x + $width / 2, $y + $height / 2)
    } else {
        $shape = $Page.DrawRectangle($x - $width / 2, $y - $height / 2, $x + $width / 2, $y + $height / 2)
        $shape.CellsU('Rounding').FormulaU = '0.08 in'
    }

    $shape.Text = [string] (Get-PropertyValue $Node 'text' (Get-PropertyValue $Node 'id' 'Node'))
    $shape.CellsU('FillForegnd').FormulaU = [string] (Get-PropertyValue $Node 'fill' 'RGB(245, 247, 250)')
    $shape.CellsU('LineColor').FormulaU = [string] (Get-PropertyValue $Node 'line' 'RGB(58, 89, 128)')
    $shape.CellsU('LineWeight').FormulaU = '1.25 pt'
    $shape.CellsU('Char.Size').FormulaU = '10 pt'
    $shape.CellsU('Para.HorzAlign').FormulaU = '1'

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
    $line.CellsU('LineWeight').FormulaU = '1.25 pt'

    $style = [string] (Get-PropertyValue $Link 'style' 'arrow')
    if ($style -ne 'line') {
        $line.CellsU('EndArrow').FormulaU = '13'
    }

    $text = [string] (Get-PropertyValue $Link 'text' '')
    if ($text.Length -gt 0) {
        $line.Text = $text
        $line.CellsU('Char.Size').FormulaU = '8 pt'
    }

    return $line
}

function Add-Title {
    param($Page, [string] $Title, [double] $PageWidth, [double] $PageHeight)

    if ([string]::IsNullOrWhiteSpace($Title)) { return }

    $shape = $Page.DrawRectangle(0.75, $PageHeight - 0.85, $PageWidth - 0.75, $PageHeight - 0.25)
    $shape.Text = $Title
    $shape.CellsU('FillPattern').FormulaU = '0'
    $shape.CellsU('LinePattern').FormulaU = '0'
    $shape.CellsU('Char.Size').FormulaU = '18 pt'
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
    $shape.CellsU('FillForegnd').FormulaU = [string] (Get-PropertyValue $Note 'fill' 'RGB(245, 247, 250)')
    $shape.CellsU('LineColor').FormulaU = [string] (Get-PropertyValue $Note 'line' 'RGB(190, 190, 190)')
    $shape.CellsU('Char.Size').FormulaU = '9 pt'
}

if ($SpecPath) {
    if (-not (Test-Path -LiteralPath $SpecPath)) {
        throw "SpecPath does not exist: $SpecPath"
    }
    $spec = Get-Content -Raw -LiteralPath $SpecPath | ConvertFrom-Json
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
