run:
	docker compose up

stop:
	docker compose down

reload:
	docker compose kill -s HUP nginx
