#set env vars
set -o allexport; source .env; set +o allexport;

#wait until the server is ready
echo "Waiting for software to be ready ..."
sleep 240s;

docker-compose exec -T taiga-back ./manage.py shell -c "from taiga.users.models import User; User.objects.create_superuser('admin', '"${ADMIN_EMAIL}"', '"${ADMIN_PASSWORD}"')"

docker-compose exec -T taiga-back sh -c "python manage.py collectstatic"