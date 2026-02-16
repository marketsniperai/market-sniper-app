
# Force delete Worktree folder
rmdir /s /q "C:\MSR\MSR_STASH_RESCUE" 2>nul
if exist "C:\MSR\MSR_STASH_RESCUE" echo Failed to delete MSR_STASH_RESCUE

# Prune git worktrees
git worktree prune

# Delete stale branches (ignoring errors if they don't exist)
git branch -D checkpoint/d51_post_e 2>nul
git branch -D chore/repo-hygiene-d37-00-1 2>nul
git branch -D master 2>nul
git branch -D sims-no-false-gold 2>nul

echo CLEANUP COMPLETE
