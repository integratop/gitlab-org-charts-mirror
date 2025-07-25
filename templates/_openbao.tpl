{{/*
Returns the hostname.
If the hostname is set in `global.hosts.openbao.name`, that will be returned,
otherwise the hostname will be assembled using `openbao` as the prefix, and the `gitlab.assembleHost` function.
*/}}
{{- define "gitlab.openbao.hostname" -}}
{{- coalesce .Values.global.openbao.host .Values.global.hosts.openbao.name (include "gitlab.assembleHost"  (dict "name" "openbao" "context" . )) -}}
{{- end -}}

{{/*
Returns the OpenBao Url, ex: `http://openbao.example.com`

Populated from one of:
- Direct setting of URL
- Populated by  "gitlab.openbao.hostname", plus `https` boolean
*/}}
{{- define "gitlab.openbao.url" -}}
{{- if $.Values.global.openbao.url -}}
{{-   $.Values.global.openbao.url -}}
{{- else -}}
{{-   if has true (list .Values.global.openbao.https .Values.global.hosts.https .Values.global.hosts.openbao.https) -}}
{{-    printf "https://%s" (include "gitlab.openbao.hostname" .) -}}
{{-   else -}}
{{-    printf "http://%s" (include "gitlab.openbao.hostname" .) -}}
{{-   end -}}
{{- end -}}
{{- end -}}

{{/*
Returns the OpenBao internal hostname.
If the hostname is set in `global.openbao.internal_host`, that will be returned,
otherwise falls back to the regular hostname.
*/}}
{{- define "gitlab.openbao.internal_hostname" -}}
{{- coalesce .Values.global.openbao.internal_host (include "gitlab.openbao.hostname" .) -}}
{{- end -}}

{{/*
Returns the OpenBao internal URL, ex: `https://openbao.internal.net`

Populated from one of:
- Direct setting of internal_url
- Populated by "gitlab.openbao.internal_hostname", plus `https` boolean
- Empty if neither internal_url nor internal_host are set
*/}}
{{- define "gitlab.openbao.internal_url" -}}
{{- if $.Values.global.openbao.internal_url -}}
{{-   $.Values.global.openbao.internal_url -}}
{{- else if $.Values.global.openbao.internal_host -}}
{{-   if has true (list .Values.global.openbao.https .Values.global.hosts.https .Values.global.hosts.openbao.https) -}}
{{-    printf "https://%s" .Values.global.openbao.internal_host -}}
{{-   else -}}
{{-    printf "http://%s" .Values.global.openbao.internal_host -}}
{{-   end -}}
{{- end -}}
{{- end -}}


