#!/usr/bin/env nextflow

// Simplified version demonstrating the core issue from ticket #6870
// Copied from: https://github.com/openpipelines-bio/openpipeline/blob/v3.0/target/nextflow/workflows/ingestion/cellranger_multi/main.nf

params.param_list = []
params.output_dir = "results"

/**
 * Guess the param list format based on the param_list object
 * This is the key function that allows param_list to be either:
 * - A file path (string ending in .csv, .json, .yaml)
 * - A direct array/list of objects ("asis")
 */
def _paramListGuessFormat(param_list) {
  if (param_list !instanceof String) {
    "asis"
  } else if (param_list.endsWith(".csv")) {
    "csv"
  } else if (param_list.endsWith(".json") || param_list.endsWith(".jsn")) {
    "json"
  } else if (param_list.endsWith(".yaml") || param_list.endsWith(".yml")) {
    "yaml"
  } else {
    "yaml_blob"
  }
}

/**
 * Read the param list - handles multiple formats
 * When format is "asis", it accepts the list directly (this is where objects come through)
 */
def _parseParamList(param_list) {
  // first determine format by extension
  def paramListFormat = _paramListGuessFormat(param_list)

  def paramListPath = (paramListFormat != "asis" && paramListFormat != "yaml_blob") ?
    file(param_list, hidden: true) :
    null

  // get the correct parser function for the detected params_list format
  def paramSets = []
  if (paramListFormat == "asis") {
    // This is where arrays of objects come through directly!
    // The schema says it should be a string (file path), but the code accepts lists
    paramSets = param_list
  } else if (paramListFormat == "yaml_blob") {
    paramSets = readYamlBlob(param_list)
  } else if (paramListFormat == "yaml") {
    paramSets = readYaml(paramListPath)
  } else if (paramListFormat == "json") {
    paramSets = readJson(paramListPath)
  } else if (paramListFormat == "csv") {
    paramSets = readCsv(paramListPath)
  } else {
    error "Format of provided --param_list not recognised.\n" +
    "Found: '$paramListFormat'.\n" +
    "Expected: a csv file, a json file, a yaml file,\n" +
    "a yaml blob or a groovy list of maps."
  }

  // data checks
  assert paramSets instanceof List: "--param_list should contain a list of maps"
  for (value in paramSets) {
    assert value instanceof Map: "--param_list should contain a list of maps"
  }

  return paramSets
}

workflow {
  log.info "=== Param List Test Workflow (Ticket #6870) ==="
  log.info ""
  log.info "Schema says: param_list is type 'string' (file path)"
  log.info "Workflow accepts: string (file) OR array of objects (asis)"
  log.info ""
  log.info "Full params: ${params}"
  log.info ""

  // Parse the param_list using cellranger_multi's actual logic
  def paramSets = _parseParamList(params.param_list)

  log.info "Format detected: ${_paramListGuessFormat(params.param_list)}"
  log.info "Successfully parsed ${paramSets.size()} parameter sets:"
  paramSets.each { data ->
    log.info "  - Sample: ${data.id}, type: ${data.library_type}, library: ${data.library_id}"
    log.info "    Input files: ${data.input}"
  }
  log.info ""
  log.info "The issue: When relaunching in Tower, these nested objects were"
  log.info "displayed as '[object Object],[object Object]' instead of JSON."
}


def readYamlBlob(str) {
  def yamlSlurper = new org.yaml.snakeyaml.Yaml()
  yamlSlurper.load(str)
}


def readYaml(file_path) {
  def inputFile = file_path !instanceof Path ? file(file_path, hidden: true) : file_path
  def yamlSlurper = new org.yaml.snakeyaml.Yaml()
  yamlSlurper.load(inputFile)
}

def readJson(file_path) {
  def inputFile = file_path !instanceof Path ? file(file_path, hidden: true) : file_path
  def jsonSlurper = new groovy.json.JsonSlurper()
  jsonSlurper.parse(inputFile)
}

// helper file: 'src/main/resources/io/viash/runners/nextflow/readwrite/readJsonBlob.nf'
def readJsonBlob(str) {
  def jsonSlurper = new groovy.json.JsonSlurper()
  jsonSlurper.parseText(str)
}

def readCsv(file_path) {
  def output = []
  def inputFile = file_path !instanceof Path ? file(file_path, hidden: true) : file_path

  // todo: allow escaped quotes in string
  // todo: allow single quotes?
  def splitRegex = java.util.regex.Pattern.compile(''',(?=(?:[^"]*"[^"]*")*[^"]*$)''')
  def removeQuote = java.util.regex.Pattern.compile('''"(.*)"''')

  def br = java.nio.file.Files.newBufferedReader(inputFile)

  def row = -1
  def header = null
  while (br.ready() && header == null) {
    def line = br.readLine()
    row += 1
    if (!line.startsWith("#")) {
      header = splitRegex.split(line, -1).collect{field ->
        m = removeQuote.matcher(field)
        m.find() ? m.replaceFirst('$1') : field
      }
    }
  }
  assert header != null: "CSV file should contain a header"

  while (br.ready()) {
    def line = br.readLine()
    row += 1
    if (line == null) {
      br.close()
      break
    }

    if (!line.startsWith("#")) {
      def predata = splitRegex.split(line, -1)
      def data = predata.collect{field ->
        if (field == "") {
          return null
        }
        def m = removeQuote.matcher(field)
        if (m.find()) {
          return m.replaceFirst('$1')
        } else {
          return field
        }
      }
      assert header.size() == data.size(): "Row $row should contain the same number as fields as the header"
      
      def dataMap = [header, data].transpose().collectEntries().findAll{it.value != null}
      output.add(dataMap)
    }
  }

  output
}
