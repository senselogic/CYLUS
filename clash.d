/*
    This file is part of the Clash distribution.

    https://github.com/senselogic/CLASH

    Copyright (C) 2017 Eric Pelzer (ecstatic.coder@gmail.com)

    Clash is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, version 3.

    Clash is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Clash.  If not, see <http://www.gnu.org/licenses/>.
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
    DeclaredClassNameMap,
    UsedClassNameMap;

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

void ProcessCssFile(
    string file_text
    )
{
    char
        character;
    long
        part_index,
        post_character_index;
    string
        class_name,
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
                      && character <= '9' )
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

        class_name = part[ 0 .. post_character_index ].replace( "\\", "" );

        if ( class_name.length > 0 )
        {
            if ( VerboseOptionIsEnabled )
            {
                writeln( "Declared : ", class_name );
            }

            DeclaredClassNameMap[ class_name ] = class_name;
        }
    }
}

// ~~

void ProcessOtherFile(
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
        class_name_array,
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

            if ( character == '"' )
            {
                break;
            }
        }

        class_name_array = part[ 0 .. post_character_index ].split( ' ' );

        foreach ( class_name; class_name_array )
        {
            if ( class_name.length > 0 )
            {
                if ( VerboseOptionIsEnabled )
                {
                    writeln( "Used : ", class_name );
                }

                UsedClassNameMap[ class_name ] = class_name;
            }
        }
    }
}

// ~~

void ProcessFile(
    string file_path
    )
{
    string
        file_text;

    file_text = ReadText( file_path );

    if ( file_path.endsWith( ".css" ) )
    {
        ProcessCssFile( file_text );
    }
    else
    {
        ProcessOtherFile( file_text );
    }
}

// ~~

void ProcessFiles(
    string[] file_path_filter_array
    )
{
    string
        file_name_filter,
        folder_path;
    SpanMode
        span_mode;

    foreach ( file_path_filter; file_path_filter_array )
    {
        SplitFilePathFilter( file_path_filter, folder_path, file_name_filter, span_mode );

        foreach ( folder_entry; dirEntries( folder_path, file_name_filter, span_mode ) )
        {
            if ( folder_entry.isFile )
            {
                ProcessFile( folder_entry.name );
            }
        }
    }
}

// ~~

void FindMissingClassNames(
    )
{
    string[]
        missing_class_name_array;

    foreach ( used_class_name; UsedClassNameMap )
    {
        if ( ( used_class_name in DeclaredClassNameMap ) is null )
        {
            missing_class_name_array ~= used_class_name;
        }
    }

    sort( missing_class_name_array );

    foreach ( missing_class_name; missing_class_name_array )
    {
        writeln( "Missing : ", missing_class_name );
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
        if ( ( declared_class_name in UsedClassNameMap ) is null )
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

void main(
    string[] argument_array
    )
{
    string
        input_folder_path,
        option,
        output_folder_path;

    argument_array = argument_array[ 1 .. $ ];

    MissingOptionIsEnabled = false;
    UnusedOptionIsEnabled = false;
    VerboseOptionIsEnabled = false;

    while ( argument_array.length >= 1
            && argument_array[ 0 ].startsWith( "--" ) )
    {
        option = argument_array[ 0 ];

        argument_array = argument_array[ 1 .. $ ];

        if ( option == "--missing" )
        {
            MissingOptionIsEnabled = true;
        }
        else if ( option == "--unused" )
        {
            UnusedOptionIsEnabled = true;
        }
        else if ( option == "--verbose" )
        {
            VerboseOptionIsEnabled = true;
        }
    }

    if ( argument_array.length > 0 )
    {
        ProcessFiles( argument_array );

        if ( MissingOptionIsEnabled )
        {
            FindMissingClassNames();
        }

        if ( UnusedOptionIsEnabled )
        {
            FindUnusedClassNames();
        }
    }
    else
    {
        writeln( "Usage :" );
        writeln( "    clash [options] <file filter> <file filter> ..." );
        writeln( "Options :" );
        writeln( "    --missing" );
        writeln( "    --unused" );
        writeln( "    --verbose" );
        writeln( "Examples :" );
        writeln( "    clash --missing --unused --verbose \"CSS/*.css\" \"PHP//*.php\"" );

        PrintError( "Invalid arguments : " ~ argument_array.to!string() );
    }
}
