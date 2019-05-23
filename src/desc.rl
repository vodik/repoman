#include "desc.h"

#include <err.h>
#include "package.h"
#include "util.h"

%%{
    machine desc;

    action store {
        parser->store[parser->pos++] = fc;
        if (parser->pos == LINE_MAX) {
            errx(1, "desc line too long");
        }
    }

    action emit {
        const char *entry = parser->store;
        const size_t entry_len = parser->pos;
        parser->store[parser->pos] = 0;
        parser->pos = 0;

        package_set(pkg, parser->entry, entry, entry_len);
    }

    header = '%FILENAME%'     %{ parser->entry = PKG_FILENAME; }
           | '%NAME%'         %{ parser->entry = PKG_PKGNAME; }
           | '%BASE%'         %{ parser->entry = PKG_PKGBASE; }
           | '%VERSION%'      %{ parser->entry = PKG_VERSION; }
           | '%DESC%'         %{ parser->entry = PKG_DESCRIPTION; }
           | '%GROUPS%'       %{ parser->entry = PKG_GROUPS; }
           | '%CSIZE%'        %{ parser->entry = PKG_CSIZE; }
           | '%ISIZE%'        %{ parser->entry = PKG_ISIZE; }
           | '%SHA256SUM%'    %{ parser->entry = PKG_SHA256SUM; }
           | '%PGPSIG%'       %{ parser->entry = PKG_PGPSIG; }
           | '%URL%'          %{ parser->entry = PKG_URL; }
           | '%LICENSE%'      %{ parser->entry = PKG_LICENSE; }
           | '%ARCH%'         %{ parser->entry = PKG_ARCH; }
           | '%BUILDDATE%'    %{ parser->entry = PKG_BUILDDATE; }
           | '%PACKAGER%'     %{ parser->entry = PKG_PACKAGER; }
           | '%REPLACES%'     %{ parser->entry = PKG_REPLACES; }
           | '%DEPENDS%'      %{ parser->entry = PKG_DEPENDS; }
           | '%CONFLICTS%'    %{ parser->entry = PKG_CONFLICTS; }
           | '%PROVIDES%'     %{ parser->entry = PKG_PROVIDES; }
           | '%OPTDEPENDS%'   %{ parser->entry = PKG_OPTDEPENDS; }
           | '%MAKEDEPENDS%'  %{ parser->entry = PKG_MAKEDEPENDS; }
           | '%CHECKDEPENDS%' %{ parser->entry = PKG_CHECKDEPENDS; }
           | '%FILES%'        %{ parser->entry = PKG_FILES; }
           | '%DELTAS%'       %{ parser->entry = PKG_FILES; };

      section = header '\n';
      contents = [^\n]+ @store %emit '\n';

      main := ( section contents* '\n' | '\n' )*;
}%%

%%write data nofinal;

void desc_parser_init(struct desc_parser *parser)
{
    *parser = (struct desc_parser){0};
    %%access parser->;
    %%write init;
}

ssize_t desc_parser_feed(struct desc_parser *parser, struct pkg *pkg,
                         char *buf, size_t buf_len)
{
    char *p = buf;
    char *pe = p + buf_len;

    %%access parser->;
    %%write exec;

    (void)desc_en_main;
    if (parser->cs == desc_error)
        return -1;

    return buf_len;
}

ssize_t read_desc(struct archive *archive, struct pkg *pkg)
{
    char *buf;
    ssize_t nbytes_r = 0;
    struct desc_parser parser;
    desc_parser_init(&parser);

    for (;;) {
        size_t bufsize;
        archive_read(archive, &buf, &bufsize);

        ssize_t result = desc_parser_feed(&parser, pkg, buf, bufsize);
        if (result < 0) {
            return result;
        } else {
            nbytes_r += result;
        }

        break;
    }

    return nbytes_r;
}
