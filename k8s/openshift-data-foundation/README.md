# OpenShift Data Foundation

## Master Node Taints

Since ODF is targeted to run nearly all component on the master nodes to make the best use of lab capacity, the following taints need to be applied manually (TODO)

```bash
oc adm taint nodes master-0.ocp.darkloft.local node-role.kubernetes.io/master:NoSchedule-
oc adm taint nodes master-0.ocp.darkloft.local node-role.kubernetes.io/master:PreferNoSchedule

oc adm taint nodes master-1.ocp.darkloft.local node-role.kubernetes.io/master:NoSchedule-
oc adm taint nodes master-1.ocp.darkloft.local node-role.kubernetes.io/master:PreferNoSchedule

oc adm taint nodes master-2.ocp.darkloft.local node-role.kubernetes.io/master:NoSchedule-
oc adm taint nodes master-2.ocp.darkloft.local node-role.kubernetes.io/master:PreferNoSchedule
```
