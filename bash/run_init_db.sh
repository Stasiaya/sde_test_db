#!/bin/bash
sudo docker pull postgres

sudo docker run \
  --name  postgres \
  -e POSTGRES_PASSWORD="@sde_password012" \
  -e POSTGRES_USER="test_sde" \
  -e POSTGRES_DB="demo" -v $HOME/sde_test_db:$HOME/sde_test_db -p 5432:5432 -d postgres

sleep 10

sudo docker exec postgres psql -U test_sde -d demo -f $HOME/sde_test_db/sql/init_db/demo.sql
