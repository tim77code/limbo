import boto3
import re

class CloudWatchMetrics(object):
    VALID = "[a-zA-Z0-9_-]+(&[a-zA-Z0-9_-]+=[^&]*)*"

    def __init__(self, config):
        cfg = config["cloudwatch"]
        if not re.match(CloudWatchMetrics.VALID, cfg):
            e = ValueError("Bad CloudWatch configuration {0}.  Must match {1}."
                           .format(cfg, CloudWatchMetrics.VALID))
            logger.error(str(e))
            raise e
        cfg = cfg.split('&')
        self._namespace = cfg[0]
        self._dims = []
        for dim in cfg[1:]:
            nv = dim.split('=')
            self._dims.append({ 'Name': nv[0], 'Value': nv[1] })
        self._client = boto3.client('cloudwatch', region_name='us-east-1')
        pass

    def events(self, count):
        self._client.put_metric_data(
            Namespace = self._namespace,
            MetricData = [
                {
                    'MetricName': 'EventCount',
                    'Dimensions': self._dims,
                    'Value': count,
                    'Unit': 'Count'
                }
            ]
        )
