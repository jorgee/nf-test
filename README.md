# nf-test
A repository for various tests and minimal-reproducible-example workflows

## Nested Object Test Pipeline (Ticket #6870)

This workflow demonstrates the issue where parameters containing nested objects are displayed as `"[object Object]"` when relaunching pipeline runs in Tower.

### The Issue

The `param_list` parameter in cellranger_multi (and similar workflows) is defined in `nextflow_schema.json` as:
- `type: "string"`
- `format: "file-path"`
- `mimetype: "text/csv"`

This schema definition indicates the parameter **should** be a file path to a CSV/JSON/YAML file.

However, the workflow's Groovy code (`_parseParamList` function) is flexible and **also accepts** direct arrays of objects:

```groovy
if (param_list instanceof List) {
  paramSets = param_list  // Use as-is when passed directly
}
```

So users can pass parameters like:

```json
{
  "param_list": [
    {
      "id": "sample1",
      "input": ["file1.fastq.gz", "file2.fastq.gz"],
      "library_type": "Gene Expression",
      "library_id": "GEX_sample1"
    }
  ]
}
```

**The Problem:** When relaunching a run in Tower, these nested objects were being converted using `.toString()`, resulting in `"[object Object],[object Object]"` instead of the actual JSON representation. This meant users couldn't see their original parameter values when relaunching.

### How the Real Workflow Handles It

The cellranger_multi workflow accepts `param_list` in multiple formats:
1. **CSV file path**: `"param_list": "samples.csv"`
2. **JSON file path**: `"param_list": "samples.json"`
3. **YAML file path**: `"param_list": "samples.yaml"`
4. **Direct list of maps**: `"param_list": [{...}, {...}]` ← This is what triggers the bug

The workflow's `_parseParamList()` function detects the format and handles each case appropriately.

### Testing

1. Run with direct parameter list (the problematic case):
   ```bash
   nextflow run main.nf -params-file params.json
   ```

2. In Tower:
   - Launch this workflow and provide `param_list` as an array of objects
   - Submit the run
   - Try to relaunch - before the fix, you'd see `"[object Object],[object Object]"`
   - After the fix, you see the actual JSON: `[{"id":"sample1",...}, {"id":"sample2",...}]`

### The Fix

The fix in `tower-web/src/app/shared/components/ngx-formly/formly-text-field/formly-text-field.component.ts` now properly serializes objects using `JSON.stringify()` instead of `.toString()`:

```typescript
if (this.field.type === 'string' && typeof value !== 'string') {
  const serializedValue = (typeof value === 'object' && value !== null)
    ? JSON.stringify(value)  // ← Proper serialization
    : value?.toString();
  this.getFormControl().setValue(serializedValue, { emitEvent: false });
}
```

### Files

- `main.nf` - Simplified workflow that mimics cellranger_multi's flexible parameter parsing
- `nextflow_schema.json` - Schema matching the cellranger_multi structure (type: string)
- `params.json` - Example with nested objects passed directly (reproduces ticket #6870)

### Reference

- Original workflow: https://github.com/openpipelines-bio/openpipeline/blob/v3.0/target/nextflow/workflows/ingestion/cellranger_multi/main.nf
- Freshdesk ticket: #6870
- Fix branch: `fix/params-nested-object-serialization`
