import {
  DynamoDBClient,
  ExportTableToPointInTimeCommand,
  ExportTableToPointInTimeCommandOutput
} from '@aws-sdk/client-dynamodb'
import {
  AthenaClient,
  GetQueryExecutionCommand,
  GetQueryResultsCommand,
  StartQueryExecutionCommand,
  StartQueryExecutionOutput,
  StartQueryExecutionCommandOutput,
  GetQueryResultsCommandOutput
} from '@aws-sdk/client-athena'
import { CreateCrawlerCommand, GlueClient, StartCrawlerCommand } from '@aws-sdk/client-glue'
import { GetParameterCommand, PutParameterCommand, SSMClient } from '@aws-sdk/client-ssm'

const dynamoClient = new DynamoDBClient({ region: 'ap-northeast-1' })
const athenaClient = new AthenaClient({ region: 'ap-northeast-1' })
const glueClient = new GlueClient({ region: 'ap-northeast-1' })
const ssmClient = new SSMClient({ region: 'ap-northeast-1' })

const TABLE_EXPORT_S3_BUCKET = process.env.TABLE_EXPORT_S3_BUCKET
const QUERY_RESULT_S3_BUCKET = process.env.QUERY_RESULT_S3_BUCKET
const DYNAMO_TABLE_ARN = process.env.DYNAMO_TABLE_ARN
const GLUE_CRAWLER_NAME = process.env.GLUE_CRAWLER_NAME
const GLUE_DATABASE_NAME = process.env.GLUE_DATABASE_NAME
const GLUE_TABLE_NAME = process.env.GLUE_TABLE_NAME
const GLUE_CRAWLER_ROLE_ARN = process.env.GLUE_CRAWLER_ROLE_ARN
const SSM_S3_EXPORT_ARN_PATH = process.env.SSM_S3_EXPORT_ARN_PATH

const sql = `SELECT Item.city.S as city, COUNT (Item.city.S) as city_count FROM "${GLUE_DATABASE_NAME}".${GLUE_TABLE_NAME} GROUP BY Item.city.S`

const EVENT_TYPE = {
  EXPORT: 'exportTable',
  RUN_CRAWLER: 'runCrawler',
  REPORT: 'report'
} as const
type EVENT_TYPE = typeof EVENT_TYPE[keyof typeof EVENT_TYPE]


// exportTable
async function exportDynamoToS3(): Promise<true> {
  const command = new ExportTableToPointInTimeCommand({ S3Bucket: TABLE_EXPORT_S3_BUCKET, TableArn: DYNAMO_TABLE_ARN })
  const result = await dynamoClient.send(command)
  await saveTargetPath(result)
  return true
}

async function saveTargetPath(result: ExportTableToPointInTimeCommandOutput): Promise<void> {
  const exportArn = result.ExportDescription?.ExportArn ?? ''
  const arnSplit = exportArn.split('/')
  const crawlerTargetPath = `${TABLE_EXPORT_S3_BUCKET}/AWSDynamoDB/${arnSplit[arnSplit.length - 1]}/data/`
  const command = new PutParameterCommand({
    Name: SSM_S3_EXPORT_ARN_PATH,
    Value: crawlerTargetPath,
    Overwrite: true
  })
  await ssmClient.send(command)
}

// runCrawler
async function getTargetPath(): Promise<string | undefined> {
  const command = new GetParameterCommand({
    Name: SSM_S3_EXPORT_ARN_PATH
  })
  const result = await ssmClient.send(command)
  return result.Parameter?.Value
}

async function createCrawler(targetPath): Promise<true> {
  const command = new CreateCrawlerCommand({
    Name: GLUE_CRAWLER_NAME,
    Role: GLUE_CRAWLER_ROLE_ARN,
    Targets: { S3Targets: [{ Path: targetPath }] },
    DatabaseName: GLUE_DATABASE_NAME
  })
  await glueClient.send(command)
  return true
}

async function startCrawler(): Promise<true> {
  const command = new StartCrawlerCommand({
    Name: GLUE_CRAWLER_NAME
  })
  await glueClient.send(command)
  return true
}

// report
async function queryAthena(QueryString: string): Promise<StartQueryExecutionCommandOutput> {
  const command = new StartQueryExecutionCommand({
    QueryString,
    ResultConfiguration: {
      OutputLocation: `s3://${QUERY_RESULT_S3_BUCKET}`
    },
    QueryExecutionContext: {
      Database: GLUE_DATABASE_NAME
    }
  })
  return await athenaClient.send(command)
}

async function sleep(): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, 1000))
}

async function getQueryExecutionState(startQueryResult: StartQueryExecutionOutput): Promise<string | undefined> {
  const command = new GetQueryExecutionCommand({
    QueryExecutionId: startQueryResult.QueryExecutionId
  })
  const result = await athenaClient.send(command)
  return result.QueryExecution?.Status?.State
}

async function getQueryResult(startQueryResult: StartQueryExecutionCommandOutput): Promise<GetQueryResultsCommandOutput> {
  // クエリの実行が終わるまで待つ
  let isPolling = true
  while (isPolling) {
    const state = await getQueryExecutionState(startQueryResult)
    isPolling = state === 'RUNNING' || state === 'QUEUED'
    await sleep()
  }

  // 実行結果の取得
  const command = new GetQueryResultsCommand({
    QueryExecutionId: startQueryResult.QueryExecutionId
  })
  return await athenaClient.send(command)
}

/**
 * lambda handler
 * @param event 
 */
export async function handler(event: any): Promise<true> {
  if (event.Records && event.Records.length > 0) {
    // s3 eventでトリガーされる時はここに入る
    const targetPath = await getTargetPath()
    await createCrawler(targetPath)
    await startCrawler()
    return true
  }

  switch (event.eventType) {
    case EVENT_TYPE.EXPORT:
      await exportDynamoToS3()
      break
    case EVENT_TYPE.RUN_CRAWLER:
      const targetPath = await getTargetPath()
      await createCrawler(targetPath)
      await startCrawler()
      break
    case EVENT_TYPE.REPORT:
      const startQueryResult = await queryAthena(sql)
      const result = await getQueryResult(startQueryResult)
      console.log(JSON.stringify(result))
      break
    default:
      break
  }
  return true
}