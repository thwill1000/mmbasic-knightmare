option explicit
option base 0
option angle degrees
option default float

#include "constants.inc"

' Global variables
dim g_debug%=0
dim g_map(MAP_SIZE) as integer ' Map data
dim g_row%                     ' Current top map row. Zero is the bottom row.
dim g_scroll_timer             ' Scroll timer
dim g_player_timer             ' Player timer
dim g_game_tick                ' The game tick
dim g_tilepx%                  ' The rendered tile row pixel
dim g_kb1%,g_kb2%,g_kb3%
dim g_x%,g_y%,g_i%             ' Auxiliary global variables

' 0-X, 1-Y, 2-Animation Flag
dim g_player(2)=(SCREEN_WIDTH/2-TILE_SIZE, SCREEN_HEIGHT-TILE_SIZE*4,0)
dim g_player_speed=.6
dim g_player_animation_time=300

init()
load_map(1)
initialize_screen_buffer()

page write 2
run_stage()
page write 0: end

sub run_stage()
    timer=0

    sprite read #1, PLAYER_SKIN1_X_L, PLAYER_SKIN_Y, PLAYER_SIZE, PLAYER_SIZE, TILES_BUFFER
    sprite read #2, PLAYER_SKIN1_X_R, PLAYER_SKIN_Y, PLAYER_SIZE, PLAYER_SIZE, TILES_BUFFER
    sprite show g_player(2)+1,g_player(0),g_player(1),2

    do
        ' Process game logic and the sprites and map rendering
        if timer >= g_game_tick then
            ' Process keyboard
            g_kb1%=KeyDown(1): g_kb2%=KeyDown(2): g_kb3%=KeyDown(3)
            if g_kb1% or g_kb2% or g_kb3% then process_kb()

            ' Process sprites
            sprite show g_player(2)+1,g_player(0),g_player(1),2

            ' Map rendering
            page write 0
            blit 0,TILE_SIZE, SCREEN_OFFSET,0, SCREEN_WIDTH,SCREEN_HEIGHT, SCREEN_BUFFER
            page write SCREEN_BUFFER

            g_game_tick=timer+GAME_TICK
        end if

        ' Scrolls the map
        if timer >= g_scroll_timer then
            sprite scroll 0,-1
            inc g_tilepx%,1
            g_scroll_timer=timer+SCROLL_SPEED
        end if

        ' Process player animation
        if timer >= g_player_timer then
            sprite hide g_player(2)+1
            g_player(2)=not g_player(2)
            g_player_timer=timer+g_player_animation_time
        end if

        ' Draw the next map tile row
        if g_tilepx% = TILE_SIZE then
            inc g_row%,-1
            if g_row% < 0 then exit do
            draw_map_row(g_row%)
            g_tilepx%=0
        end if

        if g_debug% then
            page write 0
            print@(0,200) "r: "+str$(g_row%)+" kb1: "+str$(g_kb1%)+" kb2: "+str$(g_kb2%)+" kb3: "+str$(g_kb3%)+"  "
            page write SCREEN_BUFFER
        end if
    loop
end sub

sub process_kb()
    if g_kb1%=KB_UP or g_kb2%=KB_UP then
        inc g_player(1), -g_player_speed
        if g_player(1) < TILE_SIZE * 4 then g_player(1)=TILE_SIZE * 4
    end if

    if g_kb1%=KB_DOWN or g_kb2%=KB_DOWN then
        inc g_player(1), g_player_speed
        if g_player(1) > SCREEN_HEIGHT - TILE_SIZE then g_player(1)=SCREEN_HEIGHT - TILE_SIZE
    end if

    if g_kb1%=KB_LEFT or g_kb2%=KB_LEFT then
        inc g_player(0), -g_player_speed
        if g_player(0) < 0 then g_player(0)=SCREEN_WIDTH - TILE_SIZE * 2
    end if

    if g_kb1%=KB_RIGHT or g_kb2%=KB_RIGHT then
        inc g_player(0), g_player_speed
        if g_player(0) > SCREEN_WIDTH - TILE_SIZE * 2 then g_player(0)=0
    end if
end sub

'
' Initialize the game
sub init()
    ' screen mode
    mode 7,12 ' 320x240
    ' init screen and tiles buffers
    page write SCREEN_BUFFER:cls
    page write TILES_BUFFER:cls
    load png TILESET_IMG
    ' clear screen
    page write 0: cls
    ' init game state variables
    g_row%=MAP_ROWS-SCREEN_ROWS-1
    g_tilepx%=0
end sub

'
' Draw map row to the top of the screen buffer
sub draw_map_row(row%)
    local tile%,col%,tx%,ty%

    page write SCREEN_BUFFER
    for col%=MAP_COLS_0 to 0 step -1
        tile%=(g_map(row%*MAP_COLS+col%) AND &HFF)-1
        tx%=(tile% MOD TILES_COLS) * TILE_SIZE
        ty%=(tile% \ TILES_COLS) * TILE_SIZE
        blit tx%,ty%, col%*TILE_SIZE,0, TILE_SIZE,TILE_SIZE, TILES_BUFFER
    next
    page write 0
end sub

'
' Draw initial screen to the screen buffer
sub initialize_screen_buffer()
    local row%

    page write SCREEN_BUFFER
    for row%=MAP_ROWS_0 to MAP_ROWS_0 - (SCREEN_ROWS + 0) step -1
        draw_map_row(row%)
        page scroll SCREEN_BUFFER,0,-TILE_SIZE
    next
    page scroll SCREEN_BUFFER,0,TILE_SIZE
end sub

'
' Load the map to the map global array g_map
sub load_map(num%)
    local i%=0
    local file_name$ = MAPS_DIR + "stage" + str$(num%) + ".map"
    open file_name$ for input as #1
    do while not eof(1)
        g_map(i%)=(asc(input$(1, #1)) << 8) OR asc(input$(1, #1))
        inc i%
    loop
    close #1
end sub

'
' Show the game intro
sub intro()
    local kb%
    do while kb% <> KB_SPACE
        kb%=KeyDown(1)
        if kb% = KB_ESC then mode 1:end
    loop
end sub
