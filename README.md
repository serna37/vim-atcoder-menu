# Dependency
```sh
# need
pip3 install online-judge-tools
npm install -g atcoder-cli

# chk
acc check-oj
```

# Initiate workspace
mkdir for contests by `acc new`. here is the sample shell.
```sh
# sample for C++, abc100
cd "/path/to/work/space"
contest_cd="abc100"
file_name="main.cpp"

# login
acc check-oj
oj login https://atcoder.jp
acc login
acc config default-task-choice all
acc config default-test-dirname-format test

# contest-id checkt
valid=`acc contest $contest_cd`
if [[ $valid == ''  ]]; then
    echo -e "[\e[31mERROR\e[m]create faild."
    return
fi

# mkdir & file
acc new $contest_cd
cd $contest_cd
dirs=(`\fd -d 1 -t d`)
#no fd, you can use "find"
#dirs=(`\find . -type d -maxdepth 1 -mindepth 1`)
for v in ${dirs[@]}; do
    echo -e "[\e[34mINFO\e[m]create file :\e[32m${v}${file_name}\e[m"
    touch "${v}${file_name}"
done
vi -c "AtCoderStartify" -c "AtCoderTimer"
```

# Usage
`<Leader>a` open menu.

| Feature | Description | Custom |
|:-----------|:------------|:-----------|
| Test       | Test current window program by `oj t`. |`g:ac_vim_pg_file` , `g:ac_vim_test_cmd`|
| CheckOut    | Checkout problem (ex. a/main.cpp -> b/main.cpp) with preview problem. ||
| Timer start| Open popup timer and start.  |`g:ac_vim_bell_times_at`, `g:ac_vim_bell_times_interval`, `g:ac_vim_bell_times_redzone`|
| Timer stop| Stop timer and close popup.|
| Submit | Submit current window program.<br />command is `oj s -y https://atcoder.jp/contests/{contest-id}/tasks/{contest-id}_{task-id}`.||

To set logo for [startify](https://github.com/mhinz/vim-startify).
```vim
:AtCoderStartify

```

To start timer. (menu also includes timer)
```vim
:AtCoderTimer
```

so, you should start vim by
```sh
vi -c "AtCoderStartify" -c "AtCoderTimer"
```

# Custom
```vim
" default key map (0 to disable) (default 1)
let g:ac_vim_default_keymap = 1

" create program file (default main.cpp)
let g:ac_vim_pg_file = 'main.cpp'

" test cmd (default here)
let g:ac_vim_test_cmd = 'g++ -std=c++20 main.cpp && oj t'

" timer bell at. (default 1, 3, 8, 18, 40 min)
let g:ac_vim_bell_times_at = [1, 3, 8, 18, 40]

" timer bell interval. (default 20 min)
let g:ac_vim_bell_times_interval = [20]

" timer color red. (default 90 min)
let g:ac_vim_bell_times_redzone = 90
```
