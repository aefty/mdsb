% DATA  =  N x 12
% K     =  N x N
% INFO  =  {dim,time,clock,size,select}
% E     =  N x 1
% A     =  N x 3

function [PE,A] = spring (DATA,REL,K,INFO)

    data_size = INFO.size;
    selector = INFO.select;
    domain = INFO.domain;
    dim = INFO.dim;

    e = DATA(:,selector.data.pe);
    x = DATA(:,selector.data.x);
    v = DATA(:,selector.data.v);
    a = DATA(:,selector.data.a);
    m = DATA(:,selector.data.m);

    r = REL.r;
    r_norm = REL.r_norm;
    r_theta = REL.r_theta;

    A = zeros(size(x));
    F = -K.*r_norm;

    for d = 1:dim
        A(:,d) = sum(F.* r_theta(:,:,d))'./m;
    end

    E = 0.5.*K.*(r_norm./2).^2;
    PE = sum(E)';
end