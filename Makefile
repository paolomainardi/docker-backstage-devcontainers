cli:
	@docker-compose run --rm -u root cli chown -R node:node .cache
	@docker-compose run --rm cli bash