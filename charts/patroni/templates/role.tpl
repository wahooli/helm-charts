{{- if and .Values.serviceAccount.create .Values.patroni.roleCreate -}}
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: {{ include "common.helpers.names.fullname" . }}
  namespace: {{ .Release.Namespace | default "default" }}
rules:
- apiGroups:
  - ""
  resources:
  - configmaps
  verbs:
  - create
  - get
  - list
  - patch
  - update
  - watch
  # delete and deletecollection are required only for 'patronictl remove'
  - delete
  - deletecollection
- apiGroups:
  - ""
  resources:
  - endpoints
  verbs:
  - get
  - patch
  - update
  # the following three privileges are necessary only when using endpoints
  - create
  - list
  - watch
  # delete and deletecollection are required only for for 'patronictl remove'
  - delete
  - deletecollection
- apiGroups:
  - ""
  resources:
  - pods
  verbs:
  - get
  - list
  - patch
  - update
  - watch
# The following privilege is only necessary for creation of headless service
# for patronidemo-config endpoint, in order to prevent cleaning it up by the
# k8s master. You can avoid giving this privilege by explicitly creating the
# service like it is done in this manifest (lines 2..10)
- apiGroups:
  - ""
  resources:
  - services
  verbs:
  - create
---

apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: {{ include "common.helpers.names.fullname" . }}
  namespace: {{ .Release.Namespace | default "default" }}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: {{ include "common.helpers.names.fullname" . }}
subjects:
- kind: ServiceAccount
  name: {{ include "common.helpers.names.serviceAccount" . }}
{{- end }}