component: buildbot.yml

upstream          = upstream
upstreamdest      = $(upstream)/buildbot/kubernetes
upstreamchartpath = $(upstreamdest)

# helmreponame = buildbot
# helmrepourl  = https://buildbot-kubernetes.github.io/charts/stable
# upstreamurl       = buildbot/buildbot
# upstreamversion   = 0.0.10

upstreamurl       = https://github.com/Zempashi/buildbot_kubernetes_deployment.git
upstreamversion   = master

templatename = buildbot

include ../../../iac.mk
include ../subsystem.mk

# helmprocess-setnamespace: helmupstream
# yaml: helmprocess-setnamespace

copyprocess: gitupstream

yaml: copyprocess

