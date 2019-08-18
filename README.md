Este respoitório foi baseado (neste repositório)[https://github.com/sequenceiq/hadoop-docker]
# Aquela Tecnologia Hadoop 2.9.2 Docker image

[![DockerPulls](https://img.shields.io/docker/pulls/aquelatecnologia/hadoop.svg)](https://registry.hub.docker.com/u/aquelatecnologia/hadoop/)
[![DockerStars](https://img.shields.io/docker/stars/aquelatecnologia/hadoop.svg)](https://registry.hub.docker.com/u/aquelatecnologia/hadoop/)


# Compilar localmente
Para gerar a imagem localmente sem precisar baixa-la do servidor basta executar o comando:

```
docker build -t aquelatecnologia/hadoop:2.9.2 .
```

Feito isso pode-se testar usando o comando

```
docker run -it aquelatecnologia/hadoop:2.9.2 /etc/bootstrap.sh -bash
```

# Usando do Docker-Compose
Para usar o docker-compose basta executar o seguinte comando:

```
docker-compose up
```

## Testando

Para testar o hadoop, basta executar o seguinte comando dentro do container:

```
$HADOOP_HOME/bin/hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.9.2.jar grep input output 'dfs[a-z.]+'

# verificar a saída
$HADOOP_HOME/bin/hdfs dfs -cat output/*
```
