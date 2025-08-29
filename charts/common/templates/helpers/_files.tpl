{{- define "common.helpers.files.templateFile" }}
  {{- $root := index . 0 -}}
  {{- $file := index . 1 -}}
  {{- $fileContents := $root.Files.Get $file -}}
  {{- tpl $fileContents $root -}}
{{- end }}
