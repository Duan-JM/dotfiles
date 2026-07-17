FROM mysql:8.0.31
ADD https://raw.githubusercontent.com/alibaba/nacos/master/distribution/conf/mysql-schema.sql /docker-entrypoint-initdb.d/01-nacos-mysql.sql
COPY image/mysql/8/custom-init.sql /docker-entrypoint-initdb.d/02-custom-init.sql
RUN chown -R mysql:mysql /docker-entrypoint-initdb.d/
EXPOSE 3306
CMD ["mysqld", "--character-set-server=utf8mb4", "--collation-server=utf8mb4_unicode_ci"]