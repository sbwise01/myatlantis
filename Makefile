decrypt:
	./scripts/sops.sh decrypt

encrypt:
	./scripts/sops.sh encrypt

ui:
	kubectl port-forward svc/atlantis 8080:80