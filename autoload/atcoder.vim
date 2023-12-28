aug ac_dark_color
    au!
    au ColorScheme * hi AtCoderDarkRed ctermfg=204
    au ColorScheme * hi AtCoderDarkBlue ctermfg=39
aug END
hi AtCoderDarkRed ctermfg=204
hi AtCoderDarkBlue ctermfg=39

" ############################################################################
" ###### util functions depends on acc commnad
" ###########################################################################
" get contest-id from "current work_dir" created by "acc new {contest-id}"
fu! s:acc_getcontest() abort
    retu execute('pwd')[1:]->split('/')[-1]
endf

" get task-id from "current window program file" created by "acc add"
fu! s:acc_gettask() abort
    let pg_file = get(g:, 'ac_vim_pg_file', 'main.cpp')
    let target_bufname = 'a/ini_val_is_a'
    for wid in range(1, winnr('$'))
        let bufname = bufname(winbufnr(wid))
        if stridx(bufname, pg_file) != -1
            let target_bufname = bufname
            break
        endif
    endfor
    retu split(target_bufname, '/')[0]
endf

" get task-id list from "current work_dir" create by "acc add"
fu! s:acc_gettasks() abort
    let cmd = executable('fd') ? '\fd -d 1 -t d' : 'find . -type d -maxdepth 1 -mindepth 1'
    retu system(cmd)->split('')->map({_,v->v[:0]})
endf

" get url by contest-id & task-id
fu! s:acc_geturl() abort
    let contest = s:acc_getcontest()
    let task = s:acc_gettask()
    retu 'https://atcoder.jp/contests/'.contest.'/tasks/'.contest.'_'.task
endf

" ############################################################################
" ###### util functions
" ###########################################################################
" sound for Mac
fu! s:bell_hero() abort
    if executable('afplay') && glob('/System/Library/Sounds/Hero.aiff') != -1
        cal job_start(["/bin/zsh","-c","afplay /System/Library/Sounds/Hero.aiff"])
    endif
endf
fu! s:bell_submarine() abort
    if executable('afplay') && glob('/System/Library/Sounds/Hero.aiff') != -1
        cal job_start(["/bin/zsh","-c","afplay /System/Library/Sounds/Submarine.aiff"])
    endif
endf

" ac commands result window
let s:ac_winid = -1
fu! s:open_ac_win() abort
    let current_win = winnr()
    let s:ac_winid = bufwinid('AtCoder')
    if s:ac_winid == -1
        "sil! exe 'vertical topleft new AtCoder'
        sil! exe 'vne AtCoder'
        let s:ac_winid = bufwinid('AtCoder')
        setl buftype=nofile bufhidden=hide nobuflisted modifiable
        setl nonumber norelativenumber nocursorline nocursorcolumn signcolumn=no
        " for test
        setl filetype=log
        cal matchadd('AtCoderDarkBlue', 'SUCCESS')
        "exe (current_win+1).'wincmd w'
        exe current_win.'wincmd w'
    else
        cal deletebufline(winbufnr(s:ac_winid), 1, '$')
    endif
endf

fu! s:async_ac_win(cmd) abort
    cal s:open_ac_win()
    cal job_start(["/bin/zsh","-c",a:cmd], #{out_cb: function('atcoder#async_ac_win_handler')})
endf
fu! atcoder#async_ac_win_handler(ch, msg) abort
    cal appendbufline(winbufnr(s:ac_winid), '$', a:msg)
endf

let s:border = ['─','│','─','│','╭','╮','╯','╰']

" ############################################################################
" ###### AtCoder Main Menu
" ###########################################################################
let s:ac_menu_pid = 0
let s:pmenu_default = []
let s:ac_menu_list = [
            \ '[⚙️  Test]         Test PG       | build & oj -t',
            \ '[♻️  CheckOut]     Choose Task   | cd dir & open PG',
            \ '[🖥️ View]         View Task     | open in chrome',
            \ '[⏱️ Timer Start]  100min Timer  | timer with bell',
            \ '[☕️ Timer Stop]   Take a break  | stop the timer',
            \ '[🚀 Submit]       Submit PG     | oj s -y',
            \ '[🛩️ MultiSubmit]  Multi Submit  | oj s -y',
            \ ]
fu! atcoder#ac_menu() abort
    cal popup_close(s:ac_menu_pid)
    let s:ac_menu_pid = popup_menu(s:ac_menu_list, #{title: ' AtCoder ', border: [], borderchars: s:border, callback: 's:ac_action'})
    cal setwinvar(s:ac_menu_pid, '&wincolor', 'AtCoderDarkBlue')
    cal matchadd('AtCoderDarkRed', '\[.*\]', 100, -1, #{window: s:ac_menu_pid})
    let s:pmenu_default = execute('hi PmenuSel')[1:]->split(' ')->filter({_,v->stridx(v, '=')!=-1})
    hi PmenuSel ctermbg=232 ctermfg=114
endf
fu! s:ac_action(_, idx) abort
    if a:idx == 1
        cal s:ac_test()
    elseif a:idx == 2
        cal s:ac_chkout_menu()
    elseif a:idx == 3
        cal s:ac_prob_chrome()
    elseif a:idx == 4
        cal s:atcoder_timer_start()
    elseif a:idx == 5
        cal s:atcoder_timer_stop()
    elseif a:idx == 6
        cal s:ac_submit()
    elseif a:idx == 7
        cal s:ac_submit_menu()
    endif
    exe 'hi PmenuSel '.join(s:pmenu_default, ' ')
    retu 0
endf

" ############################################################################
" ###### AtCoder TEST
" ###########################################################################
let s:ac_test_timer_id = 0
fu! s:ac_test() abort
    let test_cmd = get(g:, 'ac_vim_test_cmd', 'g++ -std=c++20 main.cpp && oj t')
    let cmd = 'cd '.s:acc_gettask().'/ && '.test_cmd
    cal s:async_ac_win(cmd)
    let s:ac_test_timer_id = timer_start(200, {tid -> s:ac_test_timer(tid)}, #{repeat: 10})
endf
fu! s:ac_test_timer(tid) abort
    for i in getbufline(winbufnr(s:ac_winid), 0, line("$"))
        if match(i, "test success") != -1
            cal s:bell_hero()
            cal timer_stop(a:tid)
            retu
        endif
    endfor
endf

" ############################################################################
" ###### AtCoder Submit
" ###########################################################################
fu! s:ac_submit() abort
    let pg_file = get(g:, 'ac_vim_pg_file', 'main.cpp')
    let task = s:acc_gettask()
    let url = s:acc_geturl()
    let cmd = 'cd '.task.' && oj s -y '.url.' '.pg_file
    cal s:async_ac_win(cmd)
endf

let s:submit_files = []
let s:submit_choose = []
let s:cwidx = 0
let s:prv_scrl_pos = 0
let s:submit_on = '✅ | '
let s:submit_off = '❌ | '
fu! s:ac_submit_menu() abort
    let pg_file = get(g:, 'ac_vim_pg_file', 'main.cpp')
    let s:cwidx = 0
    let s:prv_scrl_pos = 0
    let s:submit_files = []
    let s:submit_choose = []
    for fname in s:acc_gettasks()->map({_,v->v.'/'.pg_file})
        let buf = readfile(fname)
        if len(buf) == 0
            continue
        endif
        cal add(s:submit_files, #{chk: 1, filename: fname, preview: buf})
        cal add(s:submit_choose, s:submit_on . fname)
    endfor

    " base window
    let s:bwid = popup_create([], #{title: ' Multi Submit | Cursor: <C-n/p> | Choose: <Space> | All: <C-a> | Submit: <C-s> ',
                \ zindex: 50, mapping: 0, scrollbar: 0,
                \ border: [], borderchars: s:border,
                \ minwidth: &columns*9/12, maxwidth: &columns*9/12,
                \ minheight: &lines/2+6, maxheight: &lines/2+6,
                \ line: &lines/4-2, col: &columns/8+1,
                \ })
    cal setwinvar(s:bwid, '&wincolor', 'AtCoderDarkBlue')

    " preview window
    let s:pwid = popup_create(s:submit_files[s:cwidx].preview, #{title: ' File Preview | Scroll: <C-d/u> ',
                \ zindex: 98, mapping: 0, scrollbar: 1,
                \ border: [], borderchars: s:border,
                \ minwidth: &columns/3, maxwidth: &columns/3,
                \ minheight: &lines/2+3, maxheight: &lines/2+3,
                \ pos: 'topleft', line: &lines/4, col: &columns/2+1,
                \ firstline: 1,
                \ filter: function('s:ac_submit_preview', [0]),
                \ })
    cal setwinvar(s:bwid, '&wincolor', 'AtCoderDarkBlue')
    cal setbufvar(winbufnr(s:pwid), '&filetype', matchstr(pg_file, '[^\.]\+$'))

    " choose window
    let s:cwid = popup_create(s:submit_choose, #{title: ' Solved List ',
                \ zindex: 99, mapping: 0, scrollbar: 1,
                \ border: [], borderchars: s:border,
                \ minwidth: &columns/3, maxwidth: &columns/3,
                \ minheight: &lines/2, maxheight: &lines/2,
                \ pos: 'topleft', line: &lines/4, col: &columns/7,
                \ firstline: 1,
                \ callback: 's:ac_submit_multi',
                \ filter: function('s:ac_submit_choose', [0]),
                \ })
    cal setwinvar(s:cwid, '&wincolor', 'AtCoderDarkBlue')

    " menu highlight
    let s:pmenu_default = execute('hi PmenuSel')[1:]->split(' ')->filter({_,v->stridx(v, '=')!=-1})
    hi PmenuSel ctermbg=232 ctermfg=114
endf

fu! s:ac_submit_preview(ctx, wid, key) abort
    if a:key is# "\<Esc>"
        cal popup_close(s:bwid)
        cal popup_close(s:pwid)
        cal popup_close(s:cwid)
        cal feedkeys("\<C-c>")
    elseif a:key is# "\<Space>" || a:key is# "\<C-a>" || a:key is# "\<C-s>"
                \ || a:key is# "\<C-n>" || a:key is# "\<C-p>"
        cal popup_setoptions(s:pwid, #{zindex: 99})
        cal popup_setoptions(s:cwid, #{zindex: 100})
        cal feedkeys(a:key)
    elseif a:key is# "\<C-d>"
        "cal win_execute(self.pwid, 'exe '.lnm)
        let s:prv_scrl_pos += 20
        cal popup_setoptions(a:wid, #{cursorline: s:prv_scrl_pos})
    elseif a:key is# "\<C-u>"
        let s:prv_scrl_pos -= 20
        cal popup_setoptions(a:wid, #{cursorline: s:prv_scrl_pos})
    endif
    retu 1
endf

fu! s:ac_submit_multi_preview_upd() abort
    let win = winbufnr(s:pwid)
    sil! cal deletebufline(win, 1, getbufinfo(win)[0].linecount)
    cal setbufline(win, 1, s:submit_files[s:cwidx].preview)
    cal win_execute(s:pwid, 'exe '.1)
endf

fu! s:ac_submit_choose(ctx, wid, key) abort
    if a:key is# "\<Esc>"
        cal popup_close(s:bwid)
        cal popup_close(s:pwid)
        cal popup_close(s:cwid)
        cal feedkeys("\<C-c>")
    elseif a:key is# "\<Space>"
        let s:submit_files[s:cwidx].chk = !s:submit_files[s:cwidx].chk
        let st = s:submit_files[s:cwidx].chk ? s:submit_on : s:submit_off
        let s:submit_choose[s:cwidx] = st . s:submit_files[s:cwidx].filename

        let win = winbufnr(s:cwid)
        sil! cal deletebufline(win, 1, getbufinfo(win)[0].linecount)
        cal setbufline(win, 1, s:submit_choose)
    elseif a:key is# "\<C-a>"
        for vv in range(0, len(s:submit_files) - 1)
            let s:submit_choose[vv] = s:submit_on . s:submit_files[vv].filename
            let s:submit_files[vv].chk = 1
        endfor

        let win = winbufnr(s:cwid)
        sil! cal deletebufline(win, 1, getbufinfo(win)[0].linecount)
        cal setbufline(win, 1, s:submit_choose)
    elseif a:key is# "\<C-s>"
    elseif a:key is# "\<C-n>"
        let s:cwidx += 1
        if s:cwidx >= len(s:submit_choose)
            let s:cwidx = len(s:submit_choose) - 1
        endif
        cal popup_setoptions(s:cwid, #{cursorline: s:cwidx})
        "cal popup_filter_menu(s:cwid, a:key)
        "cal win_execute(s:cwid, 'exe '.s:cwidx + 1)
        cal s:ac_submit_multi_preview_upd()
    elseif a:key is# "\<C-p>"
        let s:cwidx -= 1
        if s:cwidx < 0
            let s:cwidx = 0
        endif
        "cal popup_setoptions(a:wid, #{cursorline: s:cwidx + 1})
        cal win_execute(s:cwid, 'exe '.s:cwidx + 1)
        cal s:ac_submit_multi_preview_upd()
    elseif a:key is# "\<C-d>" || a:key is# "\<C-u>"
        cal popup_setoptions(s:pwid, #{zindex: 100})
        cal popup_setoptions(s:cwid, #{zindex: 99})
        cal feedkeys(a:key)
    endif

    " TODO ショートカットキー割り当て
    "let pg_file = get(g:, 'ac_vim_pg_file', 'main.cpp')
    "exe 'e '.s:tasks[a:idx-1].'/'.pg_file
    "cal s:open_ac_win()
    "let url = s:acc_geturl()
    "let task = s:scraping_get_task(url)
    "cal appendbufline(winbufnr(s:ac_winid), '$', task)
    "cal s:ac_prob_chrome()
    retu 1
endf

fu! s:ac_submit_multi(wid, idx) abort
    exe 'hi PmenuSel '.join(s:pmenu_default, ' ')
    retu 0
endf

" TODO 進捗を描画-> atcoder window

" ############################################################################
" ###### AtCoder Checkout Task
" ###########################################################################
fu! s:scraping_get_task(url)
    let store = []
    let is_store = 0
    let start_row = '<div class="col-sm-12">'
    let end_row = '<span class="lang-en">'
    let ignore_interval = 0
    let ignore_row = [
                \ '<div ', '</div>',
                \ '<section>', '</section>',
                \ '<span ', '</span>',
                \ '<hr />',
                \ ]

    let cookieFile = readfile(glob("$HOME/Library/Application\ Support/online-judge-tools/cookie.jar"))
    let firstCookie = split(cookieFile[1], 'Set-Cookie3: ')[0]
    let secondCookie = split(cookieFile[2], 'Set-Cookie3: ')[0]
    let curlCmd = "curl -b '".firstCookie."' -b '".secondCookie."' -s ".a:url
    for row in system(curlCmd)->split('\n')
        " start / end
        if stridx(row, start_row) != -1
            let is_store = 1
        elseif stridx(row, end_row) != -1
            break
        endif

        " ignore interval
        if stridx(row, '<script>') != -1
            let ignore_interval = 1
        endif
        if stridx(row, '</script>') != -1
            let ignore_interval = 0
            continue
        endif
        if ignore_interval
            continue
        endif

        " ignore row
        let anymatch = 0
        for ig in ignore_row
            if stridx(row, ig) != -1
                let anymatch = 1
                break
            endif
        endfor
        if anymatch
            continue
        endif

        if is_store
            let row = substitute(row, '\t', '', 'g')
            let row = substitute(row, '\r', '', 'g')

            let row = substitute(row, '<h3>', '', 'g')
            let row = substitute(row, '</h3>', '', 'g')
            let row = substitute(row, '<p>', '', 'g')
            let row = substitute(row, '</p>', '', 'g')
            let row = substitute(row, '<ul>', '', 'g')
            let row = substitute(row, '</ul>', '', 'g')
            let row = substitute(row, '<li>', '', 'g')
            let row = substitute(row, '</li>', '', 'g')
            let row = substitute(row, '<var>', '', 'g')
            let row = substitute(row, '</var>', '', 'g')
            "let row = substitute(row, '<pre>', '\n', 'g')
            let row = substitute(row, '</pre>', '', 'g')
            let row = substitute(row, '<code>', '', 'g')
            let row = substitute(row, '</code>', '', 'g')
            let row = substitute(row, '<br />', '', 'g')

            let row = substitute(row, '&lt;', '<', 'g')
            let row = substitute(row, '&leq;', '<=', 'g')
            let row = substitute(row, '&gt;', '>', 'g')
            let row = substitute(row, '&geq;', '≥', 'g')

            let row = substitute(row, '\\ldots', '...', 'g')
            let row = substitute(row, '\\sqrt', '√', 'g')
            let row = substitute(row, '\\pm', '±', 'g')
            let row = substitute(row, '\\div', '÷', 'g')
            let row = substitute(row, '\\times', '×', 'g')
            let row = substitute(row, '\\neq', '≠', 'g')
            let row = substitute(row, '\\not=', '≠', 'g')
            let row = substitute(row, '\\leqq', '≦', 'g')
            let row = substitute(row, '\\leq', '≤', 'g')
            let row = substitute(row, '\\le', '≤', 'g')
            let row = substitute(row, '\\geqq', '≧', 'g')
            let row = substitute(row, '\\geq', '≥', 'g')
            let row = substitute(row, '\\ge', '≥', 'g')
            let row = substitute(row, '\\lt', '<', 'g')
            let row = substitute(row, '\\gt', '>', 'g')
            let row = substitute(row, '\\cap', '∩', 'g')
            let row = substitute(row, '\\cup', '∪', 'g')
            let row = substitute(row, '\\subseteq', '⊆', 'g')
            let row = substitute(row, '\\subset', '⊂', 'g')
            let row = substitute(row, '\\supseteq', '⊇', 'g')
            let row = substitute(row, '\\supset', '⊃', 'g')
            let row = substitute(row, '\\in', '∈', 'g')
            let row = substitute(row, '\\ni', '∋', 'g')
            let row = substitute(row, '\\vee', '∨', 'g')
            let row = substitute(row, '\\\wedge', '∧', 'g')
            let row = substitute(row, '\\cdots', '⋯', 'g')
            let row = substitute(row, '\\ldots', '…', 'g')
            let row = substitute(row, '\\vdots', '⋮', 'g')
            let row = substitute(row, '\\dots', '⋯', 'g')
            let row = substitute(row, '\\cdot', '∙', 'g')
            let row = substitute(row, '\\bullet', '⦁', 'g')
            let row = substitute(row, '\\left', '', 'g')
            let row = substitute(row, '\\right', '', 'g')
            let row = substitute(row, '\\max', 'max', 'g')
            let row = substitute(row, '\\min', 'min', 'g')
            let row = substitute(row, '\\{', '{', 'g')
            let row = substitute(row, '\\}', '}', 'g')
            let row = substitute(row, '\\ ', '', 'g')

            if stridx(row, '<pre>') != -1
                for r in split(row, '<pre>')
                    cal add(store, r)
                endfor
            else
                cal add(store, row)
            endif
        endif
    endfor
    retu store
endf

let s:tasks = -1
fu! s:ac_chkout_menu() abort
    let s:tasks = s:acc_gettasks()
    let wid = popup_menu(s:tasks, #{title: ' Tasks ', border: [], borderchars: s:border, callback: 's:ac_chkout'})
    cal setwinvar(wid, '&wincolor', 'AtCoderDarkBlue')
    let s:pmenu_default = execute('hi PmenuSel')[1:]->split(' ')->filter({_,v->stridx(v, '=')!=-1})
    hi PmenuSel ctermbg=232 ctermfg=114
endf

fu! s:ac_chkout(_, idx) abort
    let pg_file = get(g:, 'ac_vim_pg_file', 'main.cpp')
    exe 'e '.s:tasks[a:idx-1].'/'.pg_file
    cal s:open_ac_win()
    let url = s:acc_geturl()
    let task = s:scraping_get_task(url)
    cal appendbufline(winbufnr(s:ac_winid), '$', task)
    "cal s:ac_prob_chrome()
    exe 'hi PmenuSel '.join(s:pmenu_default, ' ')
    retu 0
endf

fu! s:ac_prob_chrome() abort
    let url = s:acc_geturl()
    let sh = 'open -a Google\ Chrome '.url
    sil! cal system(sh)
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
        \ border: [], borderchars: s:border, borderhighlight: ['AtCoderDarkBlue'],
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
    " bell at
    let bell = get(g:, 'ac_vim_bell_times_at', [1, 3, 8, 18, 40])
    for m in bell
        if s:actimer_sec == m*60
            cal s:bell_submarine()
        endif
    endfor
    " bell every
    let interval = get(g:, 'ac_vim_bell_times_interval', [20])
    for m in interval
        if s:actimer_sec == m*60
            cal s:bell_submarine()
        endif
    endfor
    " LPAD 0埋め
    let minutes = s:actimer_sec / 60
    let minutes = minutes < 10 ? '00'.minutes : '0'.minutes
    let seconds = s:actimer_sec % 60
    let seconds = seconds < 10 ? '0'.seconds : seconds
    " view
    let s:actimer_view = [minutes.':'.seconds]
    cal setbufline(winbufnr(s:actimer_pid), 1, s:actimer_view)
    " over 90min
    let redzone = get(g:, 'ac_vim_bell_times_redzone', 90)
    if s:actimer_sec > redzone*60
        cal matchadd('AtCoderDarkRed', '[^ ]', 16, -1, #{window: s:actimer_pid})
    endif
endf

" timer start on vim start
fu! atcoder#timer() abort
    cal s:atcoder_timer_start()
endf

" ############################################################################
" ###### AtCoder Logo
" ###########################################################################
let s:ac_logo = [
    \'                                                                           .',
    \'                                                                         .dN.',
    \'                                                                      ..d@M#J#(,',
    \'                                                                   vRMPMJNd#dbMG#(F',
    \'                                                         (O.  U6..  WJNdPMJFMdFdb#`  .JU` .Zo',
    \'                                                      .. +NM=(TB5.-^.BMDNdJbEddMd ,n.?T@3?MNm  ..',
    \'                                                     .mg@_J~/?`.a-XNxvMMW9""TWMMF.NHa._ ?_,S.Tmg|',
    \'                                                  .Js ,3,`..-XNHMT"= ...d"5Y"X+.. ?"8MNHHa.. (,b uZ..',
    \'                                                 J"17"((dNMMB"^ ..JTYGJ7"^  ?"T&JT9QJ..?"TMNNHa,?727N',
    \'                                                 .7    T"^..JT"GJv"=`             ?"4JJT9a.,?T"`  .7!',
    \'                                                         M~JY"!     ....<.Zj+,(...     .7Ta_M',
    \'                                             .JWkkWa,    d-F     .+;.ge.ga&.aa,ua+.g,     ,}#    .(Wkkkn,',
    \'                                            .W9AaeVY=-.. J;b   .XH3dHHtdHHDJHHH(HHH(WH,   J(F  ..?T4agdTH-',
    \'                                             6XkkkH=!    ,]d  .HHtdHHH.HHHbJHHH[WHHH(HHL  k.]    _7HkkkHJ:',
    \'                                             JqkP?H_      N(; TYY?YYY9(YYYD?YYYt7YYY\YY9 .Fd!     .WPjqqh',
    \'                                             .mmmH,``      d/b WHHJHH@NJHHH@dHHHFdHHHtHH#`.1#       `(dqqq]',
    \'                                            ,gmmgghJQQVb  ,bq.,YY%7YYY(YYY$?YYY^TYYY(YY^ K.]  JUQmAJmmmmg%',
    \'                                             ggggggggh,R   H,]  T#mTNNbWNN#dNN#(NN@(N@! .t#   d(Jgggggggg:',
    \'                                            .@@@@@#"_JK4,  ,bX.   ?i,1g,jge.g2+g2i,?`   K.t  .ZW&,7W@@@@@h.',
    \'                                        `..H@@@@@P   7 .H`  W/b        .^."?^(!        -1#   W, ?   T@@@@@Ma,`',
    \'                                        dH@HHHM"       U\   .N,L        ..            .$d    .B`     ."MHHH@HN.',
    \'                                   ....JMHHHHH@              ,N(p      .dH.d"77h.    .$J\              dHHHHHMU....',
    \'                                  ` WHH#,7MHHM{               ,N,h     d^.W,        .^J^               .MHHM"_d#HN.',
    \'                                   ,jH#Mo .MMW:                .W,4,  J\   Ta.-Y` .J(#                 .HMM- .M#MF!',
    \'                                     .MN/ d@?M+                  7e(h.           .3.F                  .MDd# (MML`',
    \'                                     .M4%  ?H, 7a,                .S,7a.       .Y.#^                .,"`.d=  ,PWe',
    \'                                    .! ?     dN .N,                 (N,7a.   .Y(d=                 .d! d@     4 .!',
    \'                                             .W` .!                   ?H,?GJ".d"                    ^  B',
    \'                                                                        (SJ.#=',
    \'                                                       J             ....            .M:',
    \'                                                      JUb     .   .#    (\            M~',
    \'                                                     .\.M;  .W@"` M}       .y7"m. .J"7M~ .v74e ,M7B',
    \'                                                    .F  ,N.  J]   M]       M)  JF M_  M~ d-     M`',
    \'                                                   .W,  .db, Jh.   Th...J\ /N..Y` ?N-.Ma.-M&.> .M-',
    \]

fu! atcoder#startify() abort
    let g:startify_custom_header = s:ac_logo
endf

