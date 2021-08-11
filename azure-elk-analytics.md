## Elastic analytics environment for Azure Monitor data

The context of this tip is a need for exploring a dataset from Azure Monitor. Kibana and Elasticsearch is a powerful combination 
for exploring a previously unknown set of data.


For the following commands the assumtion is that you have a Linux or OSX environment on your computer. 
A howto on the software requirements is out of scope for this document: docker, docker-compose, az cli, jq, git

### Deploy the Elastic stack
Start a stack of Elastic analytics tools using docker and deviantony's project as a starting point. This will download and initialize a full Elastic stack 
```bash
git clone https://github.com/deviantony/docker-elk.git
cd docker-elk
docker-compose up -d
```

### Get the Azure data set
Depending on your environment you should elevate with Azure Privileged Identity Management ([Azure PIM](https://docs.microsoft.com/en-us/azure/role-based-access-control/elevate-access-global-admin?toc=/azure/active-directory/privileged-identity-management/toc.json)) 
or log on to relevant subscription in https://portal.azure.com to find the workspace ID needed for exporting data.

From relevant Log Analytics workspace, get 24 hours worth of json data and pipe it through jq and gzip to produce a nicely formatted json file. 
E.g. Software inventory data stored in the table **ConfigurationData** so we specify this in a query
```bash
az login
az account set --subscription "MySubscriptionName"
workSpace=fa99b26f-2a91-416e-ae59-52112dc57a1b
az monitor log-analytics query -w $workSpace --analytics-query 'ConfigurationData' -t PT24H | jq -c '.[]' | gzip > 24h-data.json.gz
```

# Index the dataset
Spool the gz compressed file into Elasticsearch, again piping it through jq for extra formatting. 
Note also that we call for creating an index called `configdata-2021`. See links below for more details
```bash
gzcat 24h-data.json.gz| jq -c '.  | {"index": {"_index": "configdata-2021", "_type": "doc_type"}}, .' | curl -u elastic:changeme -XPOST "http://localhost:9200/_bulk" -H 'Content-Type: application/json' --data-binary @-
```
If everything went well there should now be a lot of data in Elasticsearch ready for you to visualize and analyze using Kibana. 


##Next steps
- Log on to the local Kibana instance http://localhost:5601, username `elastic` and password `changeme`.
- Create index pattern http://localhost:5601/app/management/kibana/indexPatterns using TimeGenerated as time field
- Go to Kibana to explore the data http://localhost:5601/app/discover
- Remember to set at relevant time period. E.g. last 30 hours is
   http://localhost:5601/app/discover#/?_g=(filters:!(),refreshInterval:(pause:!t,value:0),time:(from:now-30h,to:now))

### Links
- Elasticsearch [documentation site](https://www.elastic.co/guide/index.html)
- Consider watching a few YouTube videos on how to explore and query data. E.g.: https://www.youtube.com/watch?v=t3cebUxRliA
- Link to ["Indexing bulk documents to Elasticsearch using jq"](https://vagisha23.wordpress.com/2020/07/26/indexing-bulk-documents-to-elasticsearch-using-jq/)
