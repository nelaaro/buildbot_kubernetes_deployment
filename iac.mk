.PHONY: clean tidy

# removes outputs (but also calls tidy)
clean: tidy
	@echo ---cleaning...
	@touch .dummy
	@rm -f $(ymls) .dummy || true

#removes intermediates and other things not under source control
tidy:
	@echo ---tidying...
	@touch .dummy
	@rm -rf $(upstream)
	@find yaml/base -type f ! -iname kustomization.yaml -a ! -name \.gitignore | xargs rm -f .dummy || true

.PHONY: upstream helmupstream gitupstream copyupstream

# for iac stacks getting their basecode from helm repo's
helmupstream:
	@echo ---fetching helm...
	@rm -rf $(upstream)
	@helm pull $(upstreamurl) --untar --untardir $(upstream) --version $(upstreamversion)

# for iac stacks getting their basecode from git repo's
gitupstream:
	@echo ---fetching git...
	@rm -rf $(upstream)
	@mkdir $(upstream)
	@git clone --quiet -b $(upstreamversion) $(upstreamurl) $(upstreamdest)

# a dummy "codeget" for iac stacks that host their own code in src/
copyupstream:
	@echo ---copying source...
	@rm -rf $(upstream)
	@cp -a src/ upstream/

.PHONY: yaml helmprocess copyprocess

#upstream code is processed via helm to generate yaml, i.e upstream code is a Helmchart (customized via values.yaml)
helmprocess: ctx
	@echo ---building yaml from helm...
	@helm template $(templatename) $(upstreamchartpath) -f values.yaml \
		--output-dir yaml/base > /dev/null || echo ERROR

# render helmtemple with specified namespace
helmprocess-setnamespace:
	@echo ---building yaml from helm with namespace...
	@helm template $(templatename) $(upstreamchartpath) -n $(namespace) -f values.yaml \
		--output-dir yaml/base > /dev/null || echo ERROR

#upstream code is not a Helmchart, we just copy it without overwriting kustomizations
copyprocess:
	echo ---using yaml as is, without kustomization...
	rsync -qa --exclude=".*/" --exclude=kustomization.yaml $(upstreamchartpath)/ yaml/base/

#wildcard rule that applies an overlay under yaml/overlay/
%.yml: yaml
	@echo ---building $@...
	@kustomize build yaml/overlay > $@

.PHONY: ctx helmversions helmrepo kustomize

#operations
#set context to component namespace, useful for charts that are broken otherwise
ctx:
	@echo ---setting kube context...
	@kubectl config set-context --current --namespace=$(namespace) > /dev/null
#retrieve helmchart versions
helmversions:
	@echo ---trying to see upstream chart versions...
	@helm search repo $(upstreamurl) --versions | head || echo ...nope
#add & update helm repo
helmrepo:
	@echo ---adding and updating repo...
	@helm repo add $(helmreponame) $(helmrepourl) || echo ...repo already added
	@helm repo update
#generate kustomization.yamls
kustomize: $(upstreamdest)
	@echo ---making kustomization.yaml files in yaml/base...
	@find yaml/base -type f -iname kustomization.yaml -print -delete
	@cd yaml/base && ../../../../../mkkustom
	@echo !!! now would be a good time to inspect the yaml/base/**/kustomization.yaml files and git-add them !!!
