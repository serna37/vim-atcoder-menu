aug ac_dark_color
    au!
    au ColorScheme * hi AtCoderDarkRed ctermfg=204
    au ColorScheme * hi AtCoderarkBlue ctermfg=39
aug END
au ColorScheme * hi AtCoderarkRed ctermfg=204
au ColorScheme * hi AtCoderarkBlue ctermfg=39

" ############################################################################
" ###### util functions depends on acc commnad
" ###########################################################################
" get contest-id from "current work_dir" created by "acc new {contest-id}"
fu! s:acc_getcontest() abort
    retu execute('pwd')[1:]->split('/')[-1]
endf

" get task-id from "current program file" created by "acc add"
fu! s:acc_gettask() abort
    retu expand('%')->split('/')[0]
endf

" get task-id list from "current work_dir" create by "acc add"
fu! s:acc_gettasks() abort
    let cmd = executable('fd') ? '\fd -d 1 -t d' : 'find . -type d -maxdepth 1 -mindepth 1'
    retu system(cmd)->split('')->map({_,v->v[:0]})
endf

" ############################################################################
" ###### util functions
" ###########################################################################
" sound for Mac
fu! s:bell_hero() abort
    cal job_start(["/bin/zsh","-c","afplay /System/Library/Sounds/Hero.aiff"])
endf
fu! s:bell_submarine() abort
    cal job_start(["/bin/zsh","-c","afplay /System/Library/Sounds/Submarine.aiff"])
endf

" ac commands result window
let s:ac_winid = -1
let s:ac_win_bufnr = -1
fu! s:open_ac_win() abort
    let current_win = winnr()
    let s:ac_winid = bufwinid('AtCoder')
    if s:ac_winid == -1
        sil! exe 'vertical topleft new AtCoder'
        setl buftype=nofile bufhidden=wipe nobuflisted modifiable
        setl nonumber norelativenumber nocursorline nocursorcolumn signcolumn=no
        " for test
        setl filetype=log
        let s:ac_win_bufnr = bufnr()
        cal matchadd('DarkBlue', 'SUCCESS')
    else
        cal win_gotoid(s:ac_winid)
        exe '%d'
    endif
    exe current_win.'wincmd w'
endf

fu! s:async_ac_win(cmd) abort
    cal s:open_ac_win()
    cal job_start(a:cmd,  #{callback: 's:async_ac_win_handler'})
endf
fu! s:async_ac_win_handler(ch, msg) abort
    cal appendbufline(s:ac_winid, '$', a:msg)
endf

" ############################################################################
" ###### AtCoder Main Menu
" ###########################################################################
let s:ac_menu_pid = 0
let s:ac_menu_list = [
            \ '[⚙️  Test]         Test PG      | oj command',
            \ '[⚡️ CheckOut]     Choose Task  | cd dir & open PG',
            \ '[⏱️ Timer Start]  100min Timer | timer with bell',
            \ '[☕️ Timer Stop]   Take a break | stop the timer',
            \ '[🚀 Submmit]      Submmit PG   | acc submit',
            \ ]
fu! s:ac_menu() abort
    cal popup_menu(s:ac_menu_list, #{title: ' AtCoder ', border: [], borderchars: ['─','│','─','│','╭','╮','╯','╰'], callback: 's:ac_action'})
endf
fu! s:ac_action(_, idx) abort
    if a:idx == 1
        cal s:ac_test()
    elseif a:idx == 2
        cal s:ac_chkout_menu()
    elseif a:idx == 3
        cal s:atcoder_timer_start()
    elseif a:idx == 4
        cal s:atcoder_timer_stop()
    elseif a:idx == 5
        cal s:ac_submit()
    endif
    retu 0
endf


" ############################################################################
" ###### AtCoder TEST
" ###########################################################################
let s:ac_test_timer_id = 0
fu! s:ac_test() abort
    let test_cmd = get(g:, 'ac_vim_test_cmd', 'g++ -std=c++20 main.cpp && oj t')
    let cmd = 'cd '.s:acc_gettask().'&&'.test_cmd
    cal s:async_ac_win(cmd)
    let s:ac_test_timer_id = timer_start(200, {tid -> s:ac_test_timer(tid)}, #{repeat: 10})
endf
fu! s:ac_test_timer(tid) abort
    for i in getbufline(s:ac_win_bufnr, 0, line("$"))
        if match(i, "test success") != -1
            cal s:bell_hero()
            cal timer_stop(a:tid)
            retu
        endif
    endfor
endf

" ############################################################################
" ###### AtCoder Submmit
" ###########################################################################
fu! s:ac_submit() abort
    let pg_file = get(g:, 'ac_vim_pg_file', 'main.cpp')
    let contest = s:acc_getcontest()
    let task = s:acc_gettask()
    let url = 'https://atcoder.jp/contests/'.contest.'/tasks/'.contest.'_'.task
    let cmd = 'cd '.task.' && oj s -y '.url.' '.pg_file
    cal s:async_ac_win(cmd)
endf

" ############################################################################
" ###### AtCoder Checkout Task
" ###########################################################################
let s:tasks = -1
fu! s:ac_chkout_menu() abort
    let s:tasks = s:acc_gettasks()
    cal popup_menu(s:tasks, #{title: 'tasks', border: [], borderchars: ['─','│','─','│','╭','╮','╯','╰'], callback: 's:ac_chkout'})
endf

fu! s:ac_chkout(_, idx) abort
    let pg_file = get(g:, 'ac_vim_pg_file', 'main.cpp')
    exe 'e '.s:tasks[a:idx-1].'/'.pg_file
    cal s:bell_hero()
    " TODO 問題をダウンロードしてきて、vim上で読みたい
    " XXX pythonでの問題の取得
    retu 0
endf

" ############################################################################
" ###### AtCoder Timer
" ###########################################################################
let s:actimer_sec = 0
let s:actimer_view = ['000:00']
let s:actimer_pid = -1
let s:actimer_tid = -1

" timer start
fu! s:atcoder_timer_start() abort
    let s:actimer_sec = 0
    let s:actimer_view = ['000:00']
    cal timer_stop(s:actimer_tid)
    cal popup_close(s:actimer_pid)
    let s:actimer_pid = popup_create(s:actimer_view, #{
        \ zindex: 99, mapping: 0, scrollbar: 1,
        \ border: [], borderchars: ['─','│','─','│','╭','╮','╯','╰'], borderhighlight: ['DarkBlue'],
        \ line: &lines-10, col: 10,
        \ })
    let s:actimer_tid = timer_start(1000, {tid -> s:atcoder_timer(tid)}, #{repeat: -1})
endf

" timer stop
fu! s:atcoder_timer_stop() abort
    cal timer_stop(s:actimer_tid)
    cal popup_close(s:actimer_pid)
endf

" timer settings
fu! s:atcoder_timer(tid) abort
    let s:actimer_sec += 1
    " bell at 1min, 3min, 8min, 18min, 40min
    if s:actimer_sec==60 || s:actimer_sec==180 || s:actimer_sec==480 || s:actimer_sec==1080 || s:actimer_sec==2400
        cal s:bell_submarine()
    endif
    " bell every 20min
    if s:actimer_sec>2400 && s:actimer_sec%1200==0
        cal s:bell_submarine()
    endif
    " LPAD 0埋め
    let minutes = s:actimer_sec / 60
    let minutes = minutes < 10 ? '00'.minutes : '0'.minutes
    let seconds = s:actimer_sec % 60
    if seconds < 10
        let seconds = '0'.seconds
    endif
    " view
    let s:actimer_view = [minutes.':'.seconds]
    cal setbufline(winbufnr(s:actimer_pid), 1, s:actimer_view)
    " over 90min
    if s:actimer_sec > 5400
        cal matchadd('DarkRed', '[^ ]', 16, -1, #{window: s:actimer_pid})
    endif
endf

