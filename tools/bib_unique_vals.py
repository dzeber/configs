from collections import defaultdict

import pybtex.database
import click


@click.command()
@click.argument("bibfile", type=click.Path(exists=True, dir_okay=False))
@click.argument("field", default="")
@click.option(
    "--delim", default=",", help="Delimiter between multiple values (default ',')"
)
def unique_vals(bibfile, field, delim=","):
    """Show unique values of a field across a BibTeX database.
    
    If FIELD is not given, instead shows counts of all BibTex keys used in the
    database.
    """
    bibdb = pybtex.database.parse_file(bibfile)
    uniq_vals = defaultdict(int)

    for bibkey, bibentry in bibdb.entries.items():
        if not field:
            for fld in bibentry.fields:
                uniq_vals[fld] += 1
        elif field not in bibentry.fields:
            uniq_vals["<None>"] += 1
        else:
            val_str = bibentry.fields[field]
            if delim:
                val_str = val_str.split(delim)
            else:
                val_str = (val_str,)
            for v in val_str:
                v = v.strip()
                uniq_vals[v] += 1

    vals = sorted(uniq_vals.keys())
    for v in vals:
        print(f"{v}: {uniq_vals[v]:,}")
    print(f"\nTotal database entries: {len(bibdb.entries):,}")


if __name__ == "__main__":
    unique_vals()
