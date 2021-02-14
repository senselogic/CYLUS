/*
    This file is part of the Chyle distribution.

    https://github.com/senselogic/CHYLE

    Copyright (C) 2017 Eric Pelzer (ecstatic.coder@gmail.com)

    Chyle is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, version 3.

    Chyle is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Chyle.  If not, see <http://www.gnu.org/licenses/>.
*/

// -- IMPORTS

import core.stdc.stdlib : exit;
import std.algorithm : sort;
import std.conv : to;
import std.file : dirEntries, readText, FileException, SpanMode;
import std.stdio : writeln;
import std.string : endsWith, indexOf, lastIndexOf, replace, split, startsWith;

// -- VARIABLES

bool
    MissingOptionIsEnabled,
    UnusedOptionIsEnabled,
    VerboseOptionIsEnabled;
string[ string ]
    AssignedClassNameMap,
    CssFilePathMap,
    DeclaredClassNameMap,
    FileClassNameMap,
    HtmlFilePathMap,
    IgnoredClassNameMap,
    QuotedClassNameMap;

// -- FUNCTIONS

void PrintError(
    string message
    )
{
    writeln( "*** ERROR : ", message );
}

// ~~

void Abort(
    string message
    )
{
    PrintError( message );

    exit( -1 );
}

// ~~

void Abort(
    string message,
    FileException file_exception
    )
{
    PrintError( message );
    PrintError( file_exception.msg );

    exit( -1 );
}

// ~~

string GetLogicalPath(
    string path
    )
{
    return path.replace( "\\", "/" );
}

// ~~

string ReadText(
    string file_path
    )
{
    string
        file_text;

    writeln( "Reading file : ", file_path );

    try
    {
        file_text = file_path.readText();
    }
    catch ( FileException file_exception )
    {
        Abort( "Can't read file : " ~ file_path, file_exception );
    }

    return file_text;
}

// ~~

void SplitFilePathFilter(
    string file_path_filter,
    ref string folder_path,
    ref string file_name_filter,
    ref SpanMode span_mode
    )
{
    long
        folder_path_character_count;
    string
        file_name;

    folder_path_character_count = file_path_filter.lastIndexOf( '/' ) + 1;

    folder_path = file_path_filter[ 0 .. folder_path_character_count ];
    file_name_filter = file_path_filter[ folder_path_character_count .. $ ];

    if ( folder_path.endsWith( "//" ) )
    {
        folder_path = folder_path[ 0 .. $ - 1 ];

        span_mode = SpanMode.depth;
    }
    else
    {
        span_mode = SpanMode.shallow;
    }
}

// ~~

void FindFilePaths(
    string file_path_filter,
    bool file_path_is_added
    )
{
    string
        file_name_filter,
        file_path,
        folder_path;
    SpanMode
        span_mode;

    SplitFilePathFilter( file_path_filter, folder_path, file_name_filter, span_mode );

    foreach ( folder_entry; dirEntries( folder_path, file_name_filter, span_mode ) )
    {
        if ( folder_entry.isFile )
        {
            file_path = folder_entry.name;

            if ( file_path.endsWith( ".css" ) )
            {
                if ( file_path_is_added )
                {
                    CssFilePathMap[ file_path ] = file_path;
                }
                else
                {
                    CssFilePathMap.remove( file_path );
                }
            }
            else
            {
                if ( file_path_is_added )
                {
                    HtmlFilePathMap[ file_path ] = file_path;
                }
                else
                {
                    HtmlFilePathMap.remove( file_path );
                }
            }
        }
    }
}

// ~~

void IncludeFilePaths(
    string file_path_filter
    )
{
    FindFilePaths( file_path_filter, true );
}

// ~~

void ExcludeFilePaths(
    string file_path_filter
    )
{
    FindFilePaths( file_path_filter, true );
}

// ~~

void FindDeclaredClassNames(
    string file_text
    )
{
    char
        character;
    long
        part_index,
        post_character_index;
    string
        declared_class_name,
        part;
    string[]
        part_array;

    part_array = file_text.split( '.' );

    for ( part_index = 1;
          part_index < part_array.length;
          ++part_index )
    {
        part = part_array[ part_index ];

        for ( post_character_index = 0;
              post_character_index < part.length;
              ++post_character_index )
        {
            character = part[ post_character_index ];

            if ( ( character >= 'A'
                   && character <= 'Z' )
                 || ( character >= 'a'
                      && character <= 'z' )
                 || ( character >= '0'
                      && character <= '9'
                      && post_character_index > 0 )
                 || character == '-'
                 || character == '_'
                 || character == '\\' )
            {
                if ( character == '\\'
                     && post_character_index + 1 < part.length )
                {
                    ++post_character_index;
                }
            }
            else
            {
                break;
            }
        }

        declared_class_name = part[ 0 .. post_character_index ].replace( "\\", "" );

        if ( declared_class_name.length > 0
             && ( declared_class_name in DeclaredClassNameMap ) is null
             && ( declared_class_name in IgnoredClassNameMap ) is null )
        {
            if ( VerboseOptionIsEnabled )
            {
                writeln( "Declared : ", declared_class_name );
            }

            DeclaredClassNameMap[ declared_class_name ] = declared_class_name;
        }
    }
}

// ~~

void ParseCssFiles(
    )
{
    string
        css_file_text;

    foreach ( css_file_path; CssFilePathMap )
    {
        css_file_text = ReadText( css_file_path );
        FindDeclaredClassNames( css_file_text );
    }
}

// ~~

void FindAssignedClassNames(
    string file_text
    )
{
    char
        character;
    long
        part_index,
        post_character_index;
    string
        part;
    string[]
        assigned_class_name_array,
        part_array;

    part_array = file_text.split( "class=\"" );

    for ( part_index = 1;
          part_index < part_array.length;
          ++part_index )
    {
        part = part_array[ part_index ];

        for ( post_character_index = 0;
              post_character_index < part.length;
              ++post_character_index )
        {
            character = part[ post_character_index ];

            if ( character == '"'
                 || character == '<' )
            {
                break;
            }
        }

        assigned_class_name_array = part[ 0 .. post_character_index ].split( ' ' );

        foreach ( assigned_class_name; assigned_class_name_array )
        {
            if ( assigned_class_name.length > 0
                 && ( assigned_class_name in FileClassNameMap ) is null
                 && ( assigned_class_name in IgnoredClassNameMap ) is null )
            {
                if ( VerboseOptionIsEnabled )
                {
                    writeln( "Assigned : ", assigned_class_name );
                }

                FileClassNameMap[ assigned_class_name ] = assigned_class_name;
                AssignedClassNameMap[ assigned_class_name ] = assigned_class_name;
            }
        }
    }
}

// ~~

void FindQuotedClassNames(
    string file_text
    )
{
    foreach ( declared_class_name; DeclaredClassNameMap )
    {
        if ( ( file_text.indexOf( "'" ~ declared_class_name ~ "'" ) >= 0
               || file_text.indexOf( "'." ~ declared_class_name ~ "'" ) >= 0
               || file_text.indexOf( "\"" ~ declared_class_name ~ "\"" ) >= 0
               || file_text.indexOf( "\"." ~ declared_class_name ~ "\"" ) >= 0 )
             && ( declared_class_name in FileClassNameMap ) is null
             && ( declared_class_name in IgnoredClassNameMap ) is null )
        {
            if ( VerboseOptionIsEnabled )
            {
                writeln( "Quoted : ", declared_class_name );
            }

            FileClassNameMap[ declared_class_name ] = declared_class_name;
            QuotedClassNameMap[ declared_class_name ] = declared_class_name;
        }
    }
}

// ~~

void ParseHtmlFiles(
    )
{
    string
        html_file_text;

    foreach ( html_file_path; HtmlFilePathMap )
    {
        html_file_text = ReadText( html_file_path );
        FileClassNameMap = null;
        FindAssignedClassNames( html_file_text );
        FindQuotedClassNames( html_file_text );
    }
}

// ~~

void FindUnusedClassNames(
    )
{
    string[]
        unused_class_name_array;

    foreach ( declared_class_name; DeclaredClassNameMap )
    {
        if ( ( declared_class_name in AssignedClassNameMap ) is null
             && ( declared_class_name in QuotedClassNameMap ) is null )
        {
            unused_class_name_array ~= declared_class_name;
        }
    }

    sort( unused_class_name_array );

    foreach ( unused_class_name; unused_class_name_array )
    {
        writeln( "Unused : ", unused_class_name );
    }
}

// ~~

void FindMissingClassNames(
    )
{
    string[]
        missing_class_name_array;

    foreach ( assigned_class_name; AssignedClassNameMap )
    {
        if ( ( assigned_class_name in DeclaredClassNameMap ) is null )
        {
            missing_class_name_array ~= assigned_class_name;
        }
    }

    sort( missing_class_name_array );

    foreach ( missing_class_name; missing_class_name_array )
    {
        writeln( "Missing : ", missing_class_name );
    }
}

// ~~

void ProcessFiles(
    )
{
    ParseCssFiles();
    ParseHtmlFiles();

    if ( UnusedOptionIsEnabled )
    {
        FindUnusedClassNames();
    }

    if ( MissingOptionIsEnabled )
    {
        FindMissingClassNames();
    }
}

// ~~

void main(
    string[] argument_array
    )
{
    string
        input_folder_path,
        option,
        output_folder_path;

    argument_array = argument_array[ 1 .. $ ];

    UnusedOptionIsEnabled = false;
    MissingOptionIsEnabled = false;
    VerboseOptionIsEnabled = false;

    while ( argument_array.length >= 1
            && argument_array[ 0 ].startsWith( "--" ) )
    {
        option = argument_array[ 0 ];

        argument_array = argument_array[ 1 .. $ ];

        if ( option == "--include"
                  && argument_array.length >= 1 )
        {
            IncludeFilePaths( argument_array[ 0 ].GetLogicalPath() );

            argument_array = argument_array[ 1 .. $ ];
        }
        else if ( option == "--exclude"
                  && argument_array.length >= 1 )
        {
            ExcludeFilePaths( argument_array[ 0 ].GetLogicalPath() );

            argument_array = argument_array[ 1 .. $ ];
        }
        else if ( option == "--ignore"
                  && argument_array.length >= 1 )
        {
            IgnoredClassNameMap[ argument_array[ 0 ] ] = argument_array[ 0 ];

            argument_array = argument_array[ 1 .. $ ];
        }
        else if ( option == "--unused" )
        {
            UnusedOptionIsEnabled = true;
        }
        else if ( option == "--missing" )
        {
            MissingOptionIsEnabled = true;
        }
        else if ( option == "--verbose" )
        {
            VerboseOptionIsEnabled = true;
        }
    }

    if ( argument_array.length == 0 )
    {
        ProcessFiles();
    }
    else
    {
        writeln( "Usage :" );
        writeln( "    chyle [options]" );
        writeln( "Options :" );
        writeln( "    --include <file filter>" );
        writeln( "    --exclude <file filter>" );
        writeln( "    --missing" );
        writeln( "    --unused" );
        writeln( "    --verbose" );
        writeln( "Examples :" );
        writeln( "    chyle --include \"CSS/*.css\" --include \"PHP//*.php\" --unused --missing --verbose " );

        PrintError( "Invalid arguments : " ~ argument_array.to!string() );
    }
}
