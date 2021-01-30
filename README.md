![](https://github.com/senselogic/CLASH/blob/master/LOGO/clash.png)

# Clash

CSS class usage checker.

## Installation

Install the [DMD 2 compiler](https://dlang.org/download.html) (using the MinGW setup option on Windows).

Build the executable with the following command line :

```bash
dmd -m64 clash.d
```

## Command line

```
clash [options] <file filter> <file filter> ...
```

### Options

```
--missing : find missing classes
--unused : find unused classes
--verbose : show the processing messages
```

### Example

```bash
clash --missing --unused --verbose "CSS/*.css" "PHP//*.php"
```

Find declared and used classes in the CSS and PHP files, then list missing and unused CSS classes.

## Version

1.0

## Author

Eric Pelzer (ecstatic.coder@gmail.com).

## License

This project is licensed under the GNU General Public License version 3.

See the [LICENSE.md](LICENSE.md) file for details.
